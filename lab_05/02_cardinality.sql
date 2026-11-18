\set ON_ERROR_STOP on
\pset pager off

-- Иллюстрация расчета селективности равенства по статистике имени пассажира.
WITH stats AS (
	SELECT
		c.reltuples::double precision AS table_rows,
		s.null_frac,
		CASE
			WHEN s.n_distinct < 0 THEN -s.n_distinct * c.reltuples
			ELSE s.n_distinct
		END::double precision AS distinct_names,
		s.most_common_vals::text::text[] AS mcv_names,
		s.most_common_freqs AS mcv_frequencies
	FROM pg_stats s
	JOIN pg_class c
		ON c.oid = 'bookings.tickets'::regclass
	WHERE s.schemaname = 'bookings'
		AND s.tablename = 'tickets'
		AND s.attname = 'passenger_name'
),
mcv AS (
	SELECT v.passenger_name, v.frequency
	FROM stats s
	CROSS JOIN LATERAL unnest(s.mcv_names, s.mcv_frequencies)
		AS v(passenger_name, frequency)
),
mcv_summary AS (
	SELECT
		count(*) AS value_count,
		coalesce(sum(frequency), 0) AS frequency_sum,
		min(frequency) AS least_frequency
	FROM mcv
),
names(passenger_name) AS (
	VALUES
		('ALEKSANDR IVANOV'),
		('ANNA VASILEVA')
),
estimates AS (
	SELECT
		n.passenger_name,
		s.table_rows,
		s.distinct_names,
		m.frequency IS NOT NULL AS in_mcv,
		ms.value_count AS mcv_count,
		ms.frequency_sum AS mcv_frequency_sum,
		coalesce(
			m.frequency,
			least(
				greatest(1 - s.null_frac - ms.frequency_sum, 0)
					/ greatest(s.distinct_names - ms.value_count, 1),
				coalesce(ms.least_frequency, 1)
			)
		) AS selectivity
	FROM names n
	CROSS JOIN stats s
	CROSS JOIN mcv_summary ms
	LEFT JOIN mcv m
		ON m.passenger_name = n.passenger_name
)
SELECT
	passenger_name,
	table_rows,
	distinct_names,
	in_mcv,
	mcv_count,
	mcv_frequency_sum,
	selectivity,
	greatest(1, round((table_rows * selectivity)::numeric)) AS estimated_rows
FROM estimates
ORDER BY passenger_name;

-- Для пункта г) важна уникальность ticket_no: подходящих строк не больше одной.
SELECT conname, pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'bookings.tickets'::regclass
	AND contype = 'p';
