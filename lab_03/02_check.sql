\set ON_ERROR_STOP on
\pset pager off

-- Самостоятельная проверка триггера: рабочее ABC123 не изменяется.
BEGIN ISOLATION LEVEL READ COMMITTED;

INSERT INTO bookings.bookings (book_ref, book_date, total_amount)
VALUES
	('F0A003', bookings.now(), 0),
	('F0A004', bookings.now(), 0);

INSERT INTO bookings.tickets (
	ticket_no,
	book_ref,
	passenger_id,
	passenger_name,
	outbound
)
VALUES
	('9990000000001', 'F0A003', 'TEST 000001', 'TEST ONE', TRUE),
	('9990000000002', 'F0A003', 'TEST 000002', 'TEST TWO', TRUE),
	('9990000000003', 'F0A004', 'TEST 000003', 'TEST THREE', TRUE);

-- Для арифметики триггера подходит любой существующий рейс.
INSERT INTO bookings.segments (ticket_no, flight_id, fare_conditions, price)
SELECT t.ticket_no, f.flight_id, 'Economy', t.price
FROM (
	VALUES
		('9990000000001', 100),
		('9990000000002', 200)
) AS t(ticket_no, price)
CROSS JOIN (
	SELECT min(flight_id) AS flight_id
	FROM bookings.flights
) AS f;

DO $$
BEGIN
	IF (SELECT total_amount FROM bookings.bookings WHERE book_ref = 'F0A003')
		IS DISTINCT FROM 300
	THEN
		RAISE EXCEPTION 'Ошибка INSERT: ожидалась сумма 300';
	END IF;
END;
$$;

SAVEPOINT before_changes;

UPDATE bookings.segments
SET price = 150
WHERE ticket_no = '9990000000001';

DO $$
BEGIN
	IF (SELECT total_amount FROM bookings.bookings WHERE book_ref = 'F0A003')
		IS DISTINCT FROM 350
	THEN
		RAISE EXCEPTION 'Ошибка UPDATE: ожидалась сумма 350';
	END IF;
END;
$$;

DELETE FROM bookings.segments
WHERE ticket_no = '9990000000002';

DO $$
BEGIN
	IF (SELECT total_amount FROM bookings.bookings WHERE book_ref = 'F0A003')
		IS DISTINCT FROM 150
	THEN
		RAISE EXCEPTION 'Ошибка DELETE: ожидалась сумма 150';
	END IF;
END;
$$;

-- Перенос сегмента на билет другого бронирования переносит и его стоимость.
UPDATE bookings.segments
SET ticket_no = '9990000000003'
WHERE ticket_no = '9990000000001';

DO $$
BEGIN
	IF (SELECT total_amount FROM bookings.bookings WHERE book_ref = 'F0A003')
		IS DISTINCT FROM 0
		OR (SELECT total_amount FROM bookings.bookings WHERE book_ref = 'F0A004')
		IS DISTINCT FROM 150
	THEN
		RAISE EXCEPTION 'Ошибка переноса сегмента между бронированиями';
	END IF;
END;
$$;

ROLLBACK TO SAVEPOINT before_changes;

DO $$
BEGIN
	IF (SELECT total_amount FROM bookings.bookings WHERE book_ref = 'F0A003')
		IS DISTINCT FROM 300
		OR (SELECT total_amount FROM bookings.bookings WHERE book_ref = 'F0A004')
		IS DISTINCT FROM 0
	THEN
		RAISE EXCEPTION 'Ошибка возврата к SAVEPOINT';
	END IF;

	RAISE NOTICE 'Все проверки пройдены';
END;
$$;

SELECT book_ref, total_amount
FROM bookings.bookings
WHERE book_ref IN ('F0A003', 'F0A004')
ORDER BY book_ref;

-- Отменяются и проверочные данные, и все изменения их сумм.
ROLLBACK;
