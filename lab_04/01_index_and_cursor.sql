\set ON_ERROR_STOP on
\pset pager off
\timing on

BEGIN;

-- Журналируем временные файлы только на время построения индекса.
SELECT
	rolsuper
		OR has_parameter_privilege(CURRENT_USER, 'log_temp_files', 'SET') AS can_log_temp
FROM pg_roles
WHERE rolname = CURRENT_USER
\gset

\if :can_log_temp
SET LOCAL log_temp_files = 0;
SET LOCAL client_min_messages = 'log';
\else
\echo 'Нет права на log_temp_files: для проверки временных файлов нужен журнал администратора.'
\endif

\echo '1. Построение составного индекса по имени и идентификатору пассажира'
SHOW maintenance_work_mem;

CREATE INDEX IF NOT EXISTS lab04_tickets_name_id_idx
	ON bookings.tickets (passenger_name, passenger_id);

-- COMMIT сохраняет индекс и восстанавливает локальные настройки журналирования.
COMMIT;

BEGIN;

\echo '1. Исходный план запроса в виде курсора'
SHOW cursor_tuple_fraction;

EXPLAIN (COSTS, SETTINGS)
DECLARE seats_initial CURSOR FOR
	SELECT *
	FROM bookings.seats
	ORDER BY airplane_code;

\echo '1. Уменьшаем текущую долю в десять раз'
SELECT set_config(
	'cursor_tuple_fraction',
	(current_setting('cursor_tuple_fraction')::numeric / 10)::text,
	TRUE
);

EXPLAIN (COSTS, SETTINGS)
DECLARE seats_reduced CURSOR FOR
	SELECT *
	FROM bookings.seats
	ORDER BY airplane_code;

-- EXPLAIN DECLARE показывает план, но сам курсор не открывает.
-- Отдельно открываем курсор и показываем первые десять строк.
DECLARE seats_demo CURSOR FOR
	SELECT *
	FROM bookings.seats
	ORDER BY airplane_code;

FETCH FORWARD 10 FROM seats_demo;
CLOSE seats_demo;

-- Настройка cursor_tuple_fraction возвращается к исходному значению.
COMMIT;
