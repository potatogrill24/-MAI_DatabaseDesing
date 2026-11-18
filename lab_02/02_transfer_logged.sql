\set ON_ERROR_STOP on

BEGIN;

CREATE TABLE IF NOT EXISTS bank.operation_log (
	operation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	account_from int NOT NULL REFERENCES bank.account (account_id),
	account_to int NOT NULL REFERENCES bank.account (account_id),
	amount int NOT NULL CHECK (amount > 0),
	operation_time timestamptz NOT NULL DEFAULT clock_timestamp(),
	CHECK (account_from <> account_to)
);

-- Модифицированная версия с тем же интерфейсом и кодами возврата.
CREATE OR REPLACE FUNCTION bank.trans(
	p_id_from int,
	p_id_to int,
	p_val int
)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
	m int;
	account_count int;
BEGIN
	IF p_id_from IS NULL
		OR p_id_to IS NULL
		OR p_id_from = p_id_to
		OR p_val IS NULL
		OR p_val <= 0
	THEN
		RETURN -1;
	END IF;

	-- Блокируем оба счета в одинаковом порядке для переводов в обе стороны.
	PERFORM account_id
	FROM bank.account
	WHERE account_id IN (p_id_from, p_id_to)
	ORDER BY account_id
	FOR UPDATE;

	GET DIAGNOSTICS account_count = ROW_COUNT;

	IF account_count <> 2 THEN
		RETURN -1;
	END IF;

	SELECT val INTO m
	FROM bank.account
	WHERE account_id = p_id_from;

	-- Сохраняем строгое условие со слайда: остаток должен быть больше нуля.
	IF m - p_val > 0 THEN
		UPDATE bank.account
		SET val = val - p_val
		WHERE account_id = p_id_from;

		UPDATE bank.account
		SET val = val + p_val
		WHERE account_id = p_id_to;

		INSERT INTO bank.operation_log (account_from, account_to, amount)
		VALUES (p_id_from, p_id_to, p_val);

		RETURN 0;
	END IF;

	RETURN -1;
END;
$$;

COMMIT;
