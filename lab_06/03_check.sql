\set ON_ERROR_STOP on
\pset pager off

-- Одно сравнение использует один снимок данных; EXCEPT ALL учитывает повторения.
DO $$
DECLARE
	difference_rows bigint;
BEGIN
	WITH original AS (
		SELECT t.*
		FROM bookings.tickets t, bookings.segments tf, bookings.flights f
		WHERE tf.ticket_no = t.ticket_no
			AND f.flight_id = tf.flight_id
			AND tf.fare_conditions = 'Business'
			AND f.actual_departure > f.scheduled_departure + interval '5 hour'
	),
	optimized AS (
		SELECT t.*
		FROM bookings.flights f
		JOIN bookings.segments s
			ON s.flight_id = f.flight_id
			AND s.fare_conditions = 'Business'
		JOIN bookings.tickets t
			ON t.ticket_no = s.ticket_no
		WHERE f.actual_departure - f.scheduled_departure > interval '5 hour'
	),
	differences AS (
		(SELECT * FROM original EXCEPT ALL SELECT * FROM optimized)
		UNION ALL
		(SELECT * FROM optimized EXCEPT ALL SELECT * FROM original)
	)
	SELECT count(*) INTO difference_rows
	FROM differences;

	IF difference_rows <> 0 THEN
		RAISE EXCEPTION 'Результаты отличаются: % строк', difference_rows;
	END IF;

	RAISE NOTICE 'Проверка пройдена: различий 0, повторения совпадают';
END;
$$;

SELECT
	count(*) AS matching_segments,
	count(DISTINCT s.ticket_no) AS unique_tickets
FROM bookings.segments s
JOIN bookings.flights f
	ON f.flight_id = s.flight_id
WHERE s.fare_conditions = 'Business'
	AND f.actual_departure - f.scheduled_departure > interval '5 hour';
