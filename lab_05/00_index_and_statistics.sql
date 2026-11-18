\set ON_ERROR_STOP on
\pset pager off
\timing on

SELECT version() AS postgres_version;
SELECT bookings.version() AS demo_version;

SELECT name, setting, unit
FROM pg_settings
WHERE name IN (
	'default_statistics_target',
	'work_mem',
	'random_page_cost',
	'seq_page_cost',
	'effective_cache_size',
	'max_parallel_workers_per_gather'
)
ORDER BY name;

-- Индекс сохраняется после выполнения команды.
CREATE INDEX IF NOT EXISTS lab05_tickets_passenger_name_idx
	ON bookings.tickets (passenger_name);

-- Создание обычного индекса не заменяет сбор статистики столбцов.
ANALYZE bookings.tickets;

-- Общие оценки размера таблицы; reltuples не является точным COUNT(*).
SELECT
	relname,
	reltuples::bigint AS estimated_rows,
	relpages,
	pg_size_pretty(pg_relation_size(oid)) AS table_size
FROM pg_class
WHERE oid = 'bookings.tickets'::regclass;

-- Учитываем также индексы предыдущих лабораторных, если они уже созданы.
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'bookings' AND tablename = 'tickets'
ORDER BY indexname;

-- Краткая статистика всех столбцов.
SELECT
	attname,
	null_frac,
	avg_width,
	n_distinct,
	correlation,
	coalesce(array_length(most_common_freqs, 1), 0) AS mcv_count
FROM pg_stats
WHERE schemaname = 'bookings' AND tablename = 'tickets'
ORDER BY attname;

-- Полные списки MCV, их частоты и гистограммы удобнее читать вертикально.
\x on
SELECT attname, most_common_vals, most_common_freqs, histogram_bounds
FROM pg_stats
WHERE schemaname = 'bookings' AND tablename = 'tickets'
ORDER BY attname;
\x off

-- Имеются ли расширенные статистики по нескольким столбцам/выражениям?
SELECT statistics_name, attnames, exprs, kinds
FROM pg_stats_ext
WHERE schemaname = 'bookings' AND tablename = 'tickets'
ORDER BY statistics_name;
