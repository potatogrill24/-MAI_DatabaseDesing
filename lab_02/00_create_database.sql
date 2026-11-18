\set ON_ERROR_STOP on
\pset pager off

-- Создаем отдельную базу; при повторном запуске существующие данные сохраняются.
\connect postgres

SELECT 'CREATE DATABASE lab02_bank'
WHERE NOT EXISTS (
	SELECT FROM pg_database WHERE datname = 'lab02_bank'
)
\gexec

\connect lab02_bank

BEGIN;

CREATE SCHEMA IF NOT EXISTS bank;

CREATE TABLE IF NOT EXISTS bank.account (
	account_id int,
	val int NOT NULL CHECK (val >= 0),
	PRIMARY KEY (account_id)
);

INSERT INTO bank.account (account_id, val)
VALUES
	(1, 100),
	(2, 100)
ON CONFLICT (account_id) DO NOTHING;

COMMIT;

SELECT *
FROM bank.account
ORDER BY account_id;
