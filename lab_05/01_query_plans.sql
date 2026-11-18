\set ON_ERROR_STOP on
\pset pager off
\timing on

-- Фиксируем набор доступных индексов для интерпретации выбранных планов.
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'bookings' AND tablename = 'tickets'
ORDER BY indexname;

\echo 'а) Все билеты'
-- Выполняется полная выборка; вместо миллионов строк выводится ее план.
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT *
FROM bookings.tickets;

\echo 'б) Билеты на имя ALEKSANDR IVANOV'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT *
FROM bookings.tickets
WHERE passenger_name = 'ALEKSANDR IVANOV';

\echo 'в) Билеты на имя ANNA VASILEVA'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT *
FROM bookings.tickets
WHERE passenger_name = 'ANNA VASILEVA';

\echo 'г) Билет с точным номером'
-- Номер остается строкой: ведущие нули являются частью идентификатора.
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT *
FROM bookings.tickets
WHERE ticket_no = '0005432000284';

\echo 'Фактическое количество строк каждого результата'
SELECT
	count(*) AS all_tickets,
	count(*) FILTER (
		WHERE passenger_name = 'ALEKSANDR IVANOV'
	) AS aleksandr_ivanov,
	count(*) FILTER (
		WHERE passenger_name = 'ANNA VASILEVA'
	) AS anna_vasileva,
	count(*) FILTER (
		WHERE ticket_no = '0005432000284'
	) AS exact_ticket
FROM bookings.tickets;

-- Дополнительно показываем содержимое билета из пункта г).
SELECT *
FROM bookings.tickets
WHERE ticket_no = '0005432000284';
