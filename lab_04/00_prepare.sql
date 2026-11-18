\set ON_ERROR_STOP on
\pset pager off

-- Условия эксперимента: версия сервера, настройки памяти и параллелизма.
SELECT version() AS postgres_version;
SELECT bookings.version() AS demo_version;

SELECT name, setting, unit
FROM pg_settings
WHERE name IN (
	'work_mem',
	'hash_mem_multiplier',
	'maintenance_work_mem',
	'max_parallel_maintenance_workers',
	'max_parallel_workers_per_gather',
	'cursor_tuple_fraction',
	'random_page_cost'
)
ORDER BY name;

-- Актуализируем статистику, не меняя предметные данные.
ANALYZE bookings.seats, bookings.tickets, bookings.flights,
	bookings.boarding_passes, bookings.bookings;

SELECT
	relname AS table_name,
	reltuples::bigint AS estimated_rows,
	pg_size_pretty(pg_relation_size(oid)) AS table_size
FROM pg_class
WHERE oid IN (
	'bookings.seats'::regclass,
	'bookings.tickets'::regclass,
	'bookings.flights'::regclass,
	'bookings.boarding_passes'::regclass,
	'bookings.bookings'::regclass
)
ORDER BY relname;

-- Имеющиеся индексы могут повлиять на планы «до» и «после».
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'bookings'
	AND tablename IN ('seats', 'tickets', 'bookings')
ORDER BY tablename, indexname;
