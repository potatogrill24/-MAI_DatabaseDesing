\set ON_ERROR_STOP on
\pset pager off

-- Непустой проверочный набор существует только внутри этой транзакции.
-- Вложенные файлы не выполняют COMMIT: весь пример завершается ROLLBACK.
BEGIN;

CREATE TEMP TABLE lab06_fixture_flights ON COMMIT DROP AS
SELECT
	c.flight_id,
	t.route_no,
	t.scheduled_departure + c.n * interval '1 second' AS scheduled_departure,
	t.scheduled_arrival + c.n * interval '1 second' AS scheduled_arrival,
	c.delay
FROM (
	SELECT route_no, scheduled_departure, scheduled_arrival
	FROM bookings.flights
	ORDER BY flight_id
	LIMIT 1
) AS t
CROSS JOIN (
	VALUES
		(-600001, 1, interval '6 hour'),
		(-600002, 2, interval '7 hour'),
		(-600003, 3, interval '5 hour'),
		(-600004, 4, NULL::interval),
		(-600005, 5, interval '5 hour 1 second')
) AS c(flight_id, n, delay);

INSERT INTO bookings.flights (
	flight_id,
	route_no,
	status,
	scheduled_departure,
	scheduled_arrival,
	actual_departure,
	actual_arrival
)
-- flight_id — GENERATED ALWAYS AS IDENTITY; задаем тестовые ID явно.
OVERRIDING SYSTEM VALUE
SELECT
	flight_id,
	route_no,
	CASE WHEN delay IS NULL THEN 'Scheduled' ELSE 'Arrived' END,
	scheduled_departure,
	scheduled_arrival,
	scheduled_departure + delay,
	scheduled_arrival + delay
FROM lab06_fixture_flights;

INSERT INTO bookings.bookings (book_ref, book_date, total_amount)
SELECT 'LAB006', min(scheduled_departure) - interval '1 day', 0
FROM lab06_fixture_flights;

INSERT INTO bookings.tickets (
	ticket_no,
	book_ref,
	passenger_id,
	passenger_name,
	outbound
)
VALUES
	('9996000000001', 'LAB006', 'LAB06 P1', 'TEST DUPLICATE', TRUE),
	('9996000000002', 'LAB006', 'LAB06 P2', 'TEST ECONOMY', TRUE),
	('9996000000003', 'LAB006', 'LAB06 P3', 'TEST EXACT FIVE', TRUE),
	('9996000000004', 'LAB006', 'LAB06 P4', 'TEST NULL', TRUE),
	('9996000000005', 'LAB006', 'LAB06 P5', 'TEST ABOVE FIVE', TRUE);

INSERT INTO bookings.segments (ticket_no, flight_id, fare_conditions, price)
VALUES
	('9996000000001', -600001, 'Business', 100),
	('9996000000001', -600002, 'Business', 100),
	('9996000000002', -600001, 'Economy', 100),
	('9996000000003', -600003, 'Business', 100),
	('9996000000004', -600004, 'Business', 100),
	('9996000000005', -600005, 'Business', 100);

-- Согласуем итог независимо от того, установлен ли триггер лабораторной 3.
UPDATE bookings.bookings
SET total_amount = (
	SELECT sum(s.price)
	FROM bookings.segments s
	JOIN bookings.tickets t ON t.ticket_no = s.ticket_no
	WHERE t.book_ref = 'LAB006'
)
WHERE book_ref = 'LAB006';

\echo 'Проверочный набор: исходный план'
\ir 00_original.sql

\echo 'Индексы и оптимизированный план на том же наборе'
\ir 01_indexes.sql
\ir 02_optimized.sql
\ir 03_check.sql

DO $$
DECLARE
	row_count bigint;
	ticket_count bigint;
BEGIN
	SELECT count(*), count(DISTINCT t.ticket_no)
	INTO row_count, ticket_count
	FROM bookings.tickets t
	JOIN bookings.segments s ON s.ticket_no = t.ticket_no
	JOIN bookings.flights f ON f.flight_id = s.flight_id
	WHERE t.book_ref = 'LAB006'
		AND s.fare_conditions = 'Business'
		AND f.actual_departure - f.scheduled_departure > interval '5 hour';

	IF row_count <> 3 OR ticket_count <> 2 THEN
		RAISE EXCEPTION 'Ожидались 3 строки и 2 билета, получены % и %', row_count, ticket_count;
	END IF;

	RAISE NOTICE 'Граничные случаи пройдены: 3 строки, 2 билета; ровно 5 часов, NULL и Economy исключены';
END;
$$;

-- Новые данные и созданные именно этим сценарием индексы отменяются.
-- Уже существовавшие до BEGIN индексы сохраняются.
ROLLBACK;
