\set ON_ERROR_STOP on
\pset pager off

BEGIN ISOLATION LEVEL READ COMMITTED;

SHOW transaction_isolation;

-- Повторный запуск не должен удалять или перезаписывать существующее бронирование.
DO $$
BEGIN
	IF EXISTS (SELECT FROM bookings.bookings WHERE book_ref = 'ABC123')
		OR EXISTS (
			SELECT FROM bookings.tickets
			WHERE ticket_no IN ('9991234567890', '9991234567891')
		)
	THEN
		RAISE EXCEPTION 'Идентификаторы из задания уже заняты: используйте новые для повторного примера';
	END IF;
END;
$$;

-- Находим рейсы нужного маршрута в фактической версии дампа.
-- Вылет туда не раньше даты бронирования; обратный — после прибытия туда.
CREATE TEMP TABLE lab03_selected_flights ON COMMIT DROP AS
SELECT
	out_f.flight_id AS outbound_id,
	back_f.flight_id AS inbound_id,
	out_f.scheduled_departure AS outbound_departure,
	back_f.scheduled_departure AS inbound_departure
FROM bookings.timetable out_f
JOIN bookings.airports_data dep
	ON dep.airport_code = out_f.departure_airport
JOIN bookings.airports_data arr
	ON arr.airport_code = out_f.arrival_airport
JOIN bookings.timetable back_f
	ON back_f.departure_airport = out_f.arrival_airport
	AND back_f.arrival_airport = out_f.departure_airport
	AND back_f.scheduled_departure > out_f.scheduled_arrival
WHERE dep.city ->> 'en' = 'Moscow'
	AND arr.city ->> 'en' = 'Krasnoyarsk'
	AND out_f.scheduled_departure >= bookings.now()
	AND out_f.status <> 'Cancelled'
	AND back_f.status <> 'Cancelled'
ORDER BY
	out_f.scheduled_departure,
	back_f.scheduled_departure,
	out_f.flight_id,
	back_f.flight_id
LIMIT 1;

DO $$
BEGIN
	IF NOT EXISTS (SELECT FROM lab03_selected_flights) THEN
		RAISE EXCEPTION 'В дампе нет подходящей пары будущих рейсов Москва — Красноярск — Москва';
	END IF;
END;
$$;

TABLE lab03_selected_flights;

-- Первоначальная сумма бронирования равна нулю.
INSERT INTO bookings.bookings (book_ref, book_date, total_amount)
VALUES ('ABC123', bookings.now(), 0);

SELECT book_ref, book_date, total_amount
FROM bookings.bookings
WHERE book_ref = 'ABC123';

-- В версии дампа 2025 поле outbound обязательно.
INSERT INTO bookings.tickets (
	ticket_no,
	book_ref,
	passenger_id,
	passenger_name,
	outbound
)
VALUES
	('9991234567890', 'ABC123', '1234 123456', 'IVAN PETROV', TRUE),
	('9991234567891', 'ABC123', '4321 654321', 'PETR IVANOV', TRUE);

-- Два перелета первого пассажира: триггер увеличит сумму до 21000.
INSERT INTO bookings.segments (ticket_no, flight_id, fare_conditions, price)
SELECT '9991234567890', outbound_id, 'Business', 12500
FROM lab03_selected_flights
UNION ALL
SELECT '9991234567890', inbound_id, 'Economy', 8500
FROM lab03_selected_flights;

SELECT book_ref, total_amount
FROM bookings.bookings
WHERE book_ref = 'ABC123';

-- Два перелета второго пассажира: общая сумма станет 42000.
INSERT INTO bookings.segments (ticket_no, flight_id, fare_conditions, price)
SELECT '9991234567891', outbound_id, 'Business', 12500
FROM lab03_selected_flights
UNION ALL
SELECT '9991234567891', inbound_id, 'Economy', 8500
FROM lab03_selected_flights;

-- Независимая проверка результата триггера через сумму цен всех сегментов.
SELECT
	b.book_ref,
	b.total_amount,
	count(DISTINCT t.ticket_no) AS ticket_count,
	count(*) AS segment_count,
	sum(s.price) AS calculated_total
FROM bookings.bookings b
JOIN bookings.tickets t
	ON t.book_ref = b.book_ref
JOIN bookings.segments s
	ON s.ticket_no = t.ticket_no
WHERE b.book_ref = 'ABC123'
GROUP BY b.book_ref, b.total_amount;

DO $$
BEGIN
	IF (SELECT total_amount FROM bookings.bookings WHERE book_ref = 'ABC123')
		IS DISTINCT FROM 42000
	THEN
		RAISE EXCEPTION 'Ожидалась сумма 42000: проверьте установку триггера';
	END IF;
END;
$$;

-- Сохраняем бронирование, оба билета и четыре перелета вместе.
COMMIT;
