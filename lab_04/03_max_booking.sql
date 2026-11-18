\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo '3. Максимальная сумма: план до создания индекса'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT max(total_amount) AS max_total_amount
FROM bookings.bookings;

\echo '3. Создание индекса по сумме бронирования'
CREATE INDEX IF NOT EXISTS lab04_bookings_total_amount_idx
	ON bookings.bookings (total_amount);

\echo '3. Максимальная сумма: план после создания индекса'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, TIMING OFF)
SELECT max(total_amount) AS max_total_amount
FROM bookings.bookings;

SELECT max(total_amount) AS max_total_amount
FROM bookings.bookings;
