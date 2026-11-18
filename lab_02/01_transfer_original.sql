\set ON_ERROR_STOP on

-- Функция со слайда 76: 0 — перевод выполнен, -1 — не выполнен.
-- Таблица квалифицирована схемой bank, добавлено указание языка PL/pgSQL.
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
BEGIN
	SELECT val INTO m
	FROM bank.account
	WHERE account_id = p_id_from;

	IF m - p_val > 0 THEN
		UPDATE bank.account
		SET val = val - p_val
		WHERE account_id = p_id_from;

		UPDATE bank.account
		SET val = val + p_val
		WHERE account_id = p_id_to;

		RETURN 0;
	END IF;

	RETURN -1;
END;
$$;
