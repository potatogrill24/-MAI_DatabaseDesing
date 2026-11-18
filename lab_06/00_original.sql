\set ON_ERROR_STOP on
\pset pager off
\timing on

SELECT version() AS postgres_version;
SELECT bookings.version() AS demo_version;

-- В текущем дампе здесь нет contact_data: показываем фактическую структуру.
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'bookings' AND table_name = 'tickets'
ORDER BY ordinal_position;

SELECT name, setting, unit
FROM pg_settings
WHERE name IN ('work_mem', 'random_page_cost', 'max_parallel_workers_per_gather')
ORDER BY name;

ANALYZE bookings.flights, bookings.segments, bookings.tickets;

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'bookings'
	AND tablename IN ('flights', 'segments', 'tickets')
ORDER BY tablename, indexname;

-- Селективность фильтров на фактических данных.
SELECT
	count(*) AS flights,
	count(*) FILTER (
		WHERE actual_departure > scheduled_departure + interval '5 hour'
	) AS delayed_over_five_hours
FROM bookings.flights;

SELECT
	count(*) AS segments,
	count(*) FILTER (WHERE fare_conditions = 'Business') AS business_segments
FROM bookings.segments;

\echo 'Исходный запрос: ticket_flights заменено на segments согласно дампу'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT t.*
FROM bookings.tickets t, bookings.segments tf, bookings.flights f
WHERE tf.ticket_no = t.ticket_no
	AND f.flight_id = tf.flight_id
	AND tf.fare_conditions = 'Business'
	AND f.actual_departure > f.scheduled_departure + interval '5 hour';
