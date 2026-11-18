\set ON_ERROR_STOP on
\pset pager off
\timing on

-- Разность timestamptz индексируется; сложение с произвольным interval — STABLE.
SELECT oid::regprocedure AS function_signature, provolatile
FROM pg_proc
WHERE pronamespace = 'pg_catalog'::regnamespace
	AND proname IN ('timestamptz_mi', 'timestamptz_pl_interval')
ORDER BY proname;

CREATE INDEX IF NOT EXISTS lab06_flight_delay_idx
	ON bookings.flights ((actual_departure - scheduled_departure))
	INCLUDE (flight_id);

-- Индекс хранит только бизнес-сегменты; первый ключ нужен для поиска по рейсу.
CREATE INDEX IF NOT EXISTS lab06_business_segments_idx
	ON bookings.segments (flight_id, ticket_no)
	WHERE fare_conditions = 'Business';

-- В том числе собирается статистика индексируемого выражения задержки.
ANALYZE bookings.flights, bookings.segments;

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'bookings'
	AND indexname IN ('lab06_flight_delay_idx', 'lab06_business_segments_idx')
ORDER BY indexname;

SELECT attname, null_frac, n_distinct, most_common_vals, most_common_freqs
FROM pg_stats
WHERE schemaname = 'bookings' AND tablename = 'lab06_flight_delay_idx';
