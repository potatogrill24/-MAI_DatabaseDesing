\set ON_ERROR_STOP on
\pset pager off
\timing on

-- Занятое место — место, назначенное пассажиру в boarding_passes.
-- EXPLAIN ANALYZE выполняет весь запрос, но вместо миллионов строк печатает план.
\echo '2. Подробная выборка занятых мест для всех рейсов'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT
	f.flight_id,
	f.route_no,
	f.scheduled_departure,
	bp.seat_no,
	bp.ticket_no,
	t.passenger_name
FROM bookings.flights f
JOIN bookings.boarding_passes bp
	ON bp.flight_id = f.flight_id
JOIN bookings.tickets t
	ON t.ticket_no = bp.ticket_no;

\echo '2. Первые десять строк результата для просмотра'
SELECT
	f.flight_id,
	f.route_no,
	f.scheduled_departure,
	bp.seat_no,
	bp.ticket_no,
	t.passenger_name
FROM bookings.flights f
JOIN bookings.boarding_passes bp
	ON bp.flight_id = f.flight_id
JOIN bookings.tickets t
	ON t.ticket_no = bp.ticket_no
LIMIT 10;

\echo '2. Только количество строк того же соединения'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT count(*) AS occupied_seats
FROM bookings.flights f
JOIN bookings.boarding_passes bp
	ON bp.flight_id = f.flight_id
JOIN bookings.tickets t
	ON t.ticket_no = bp.ticket_no;

-- Без фильтров по рейсу/билету внешние ключи позволяют убрать оба соединения.
\echo '2. Дополнительно: количество мест без лишних соединений'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT count(*) AS occupied_seats
FROM bookings.boarding_passes;

SELECT count(*) AS occupied_seats
FROM bookings.boarding_passes;
