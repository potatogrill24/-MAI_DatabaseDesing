\set ON_ERROR_STOP on
\pset pager off

-- 5. Каждое выполнение этого файла снова удваивает поставки проекта j1.
-- Изменения сохраняются через COMMIT.
BEGIN;

SELECT sum(qty) AS project_1_quantity_before
FROM details.spj
WHERE j_id = 'j1';

UPDATE details.spj
SET qty = qty * 2
WHERE j_id = 'j1'
RETURNING s_id, p_id, j_id, qty;

SELECT sum(qty) AS project_1_quantity_after
FROM details.spj
WHERE j_id = 'j1';

COMMIT;
