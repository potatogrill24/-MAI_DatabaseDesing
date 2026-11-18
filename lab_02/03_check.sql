\set ON_ERROR_STOP on
\pset pager off

-- Проверки выполняются после установки версии с журналом.
-- Изменения остатков и журнала откатываются в конце.
BEGIN;

DO $$
BEGIN
	IF (SELECT val FROM bank.account WHERE account_id = 1) IS DISTINCT FROM 100
		OR (SELECT val FROM bank.account WHERE account_id = 2) IS DISTINCT FROM 100
	THEN
		RAISE EXCEPTION 'Для проверки нужны исходные остатки 100 и 100';
	END IF;

	IF EXISTS (SELECT FROM bank.account WHERE account_id = 999) THEN
		RAISE EXCEPTION 'Для проверки отсутствующего счета номер 999 должен быть свободен';
	END IF;
END;
$$;

CREATE TEMP TABLE lab02_log_before ON COMMIT DROP AS
SELECT
	count(*) AS row_count,
	coalesce(max(operation_id), 0) AS last_id
FROM bank.operation_log;

-- Успешная операция должна вернуть 0, остатки станут 70 и 130.
SELECT bank.trans(1, 2, 30) AS successful_transfer_result;

SELECT *
FROM bank.account
WHERE account_id IN (1, 2)
ORDER BY account_id;

-- Показываем только запись, созданную текущей проверкой.
SELECT *
FROM bank.operation_log
WHERE operation_id > (SELECT last_id FROM lab02_log_before)
ORDER BY operation_id;

DO $$
DECLARE
	operation record;
BEGIN
	IF (SELECT val FROM bank.account WHERE account_id = 1) IS DISTINCT FROM 70
		OR (SELECT val FROM bank.account WHERE account_id = 2) IS DISTINCT FROM 130
	THEN
		RAISE EXCEPTION 'Неверные остатки после перевода';
	END IF;

	-- Все эти вызовы должны вернуть -1 без перевода и записи в журнале.
	FOR operation IN
		SELECT *
		FROM (
			VALUES
				(1, 2, 80),       -- Недостаточно средств.
				(1, 2, 70),       -- Нулевой остаток запрещен условием со слайда.
				(1, 2, 0),        -- Нулевая сумма.
				(1, 2, -10),      -- Отрицательная сумма.
				(1, 1, 10),       -- Перевод самому себе.
				(1, 999, 10),     -- Получателя нет.
				(999, 2, 10),     -- Отправителя нет.
				(1, NULL, 10),    -- Не задан получатель.
				(NULL, 2, 10),    -- Не задан отправитель.
				(1, 2, NULL)      -- Не задана сумма.
		) AS cases(id_from, id_to, amount)
	LOOP
		IF bank.trans(operation.id_from, operation.id_to, operation.amount)
			IS DISTINCT FROM -1
		THEN
			RAISE EXCEPTION 'Ошибочно разрешен перевод: %', operation;
		END IF;
	END LOOP;

	IF (SELECT count(*) FROM bank.operation_log)
		<> (SELECT row_count + 1 FROM lab02_log_before)
		OR NOT EXISTS (
			SELECT FROM bank.operation_log
			WHERE operation_id > (SELECT last_id FROM lab02_log_before)
				AND account_from = 1
				AND account_to = 2
				AND amount = 30
				AND operation_time IS NOT NULL
		)
	THEN
		RAISE EXCEPTION 'Неверное содержимое журнала';
	END IF;

	IF (SELECT val FROM bank.account WHERE account_id = 1) IS DISTINCT FROM 70
		OR (SELECT val FROM bank.account WHERE account_id = 2) IS DISTINCT FROM 130
	THEN
		RAISE EXCEPTION 'Отказанные операции изменили остатки';
	END IF;

	RAISE NOTICE 'Все проверки пройдены';
END;
$$;

ROLLBACK;

-- После отката снова 100 и 100; учебная запись журнала также отменена.
SELECT *
FROM bank.account
WHERE account_id IN (1, 2)
ORDER BY account_id;
