\set ON_ERROR_STOP on
\pset pager off

-- 1. Проверка PostgreSQL и двух подготовленных баз.
\connect demo

SELECT version() AS postgres_version;
SELECT bookings.version() AS demo_version;
\dt bookings.*

\connect simple

SELECT
	(SELECT count(*) FROM details.s) AS suppliers,
	(SELECT count(*) FROM details.p) AS parts,
	(SELECT count(*) FROM details.j) AS projects,
	(SELECT count(*) FROM details.spj) AS supplies;
