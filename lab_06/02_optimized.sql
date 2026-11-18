\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo 'Оптимизированный запрос: план выполнения'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT t.*
FROM bookings.flights f
JOIN bookings.segments s
	ON s.flight_id = f.flight_id
	AND s.fare_conditions = 'Business'
JOIN bookings.tickets t
	ON t.ticket_no = s.ticket_no
WHERE f.actual_departure - f.scheduled_departure > interval '5 hour';

\echo 'Результат запроса с сохранением повторений исходной выборки'
SELECT t.*
FROM bookings.flights f
JOIN bookings.segments s
	ON s.flight_id = f.flight_id
	AND s.fare_conditions = 'Business'
JOIN bookings.tickets t
	ON t.ticket_no = s.ticket_no
WHERE f.actual_departure - f.scheduled_departure > interval '5 hour';
