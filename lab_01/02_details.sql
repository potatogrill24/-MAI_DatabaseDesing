\set ON_ERROR_STOP on
\pset pager off

-- 4. Количество наименований красных и синих деталей в справочнике.
SELECT
	color,
	count(*) AS part_count
FROM details.p
WHERE color IN ('Красный', 'Синий')
GROUP BY color
ORDER BY color;

-- 6. Проекты, для которых нет ни одной поставки красных деталей.
-- Внешнее соединение выполняется с множеством проектов с красными поставками.
SELECT
	j.j_id,
	j.jname
FROM details.j j
LEFT JOIN (
	SELECT DISTINCT spj.j_id
	FROM details.spj spj
	JOIN details.p p
		ON p.p_id = spj.p_id
	WHERE p.color = 'Красный'
) AS red_projects
	ON red_projects.j_id = j.j_id
WHERE red_projects.j_id IS NULL
ORDER BY j.j_id;

-- 8. Число поставляемых единиц каждого цвета по поставщикам: INNER JOIN.
SELECT
	s.s_id,
	s.sname,
	p.color,
	sum(spj.qty) AS supplied_quantity
FROM details.s s
INNER JOIN details.spj spj
	ON spj.s_id = s.s_id
INNER JOIN details.p p
	ON p.p_id = spj.p_id
GROUP BY s.s_id, s.sname, p.color
ORDER BY s.s_id, p.color;

-- Тот же отчет с LEFT JOIN: сохраняет и поставщиков без поставок.
SELECT
	s.s_id,
	s.sname,
	p.color,
	coalesce(sum(spj.qty), 0) AS supplied_quantity
FROM details.s s
LEFT JOIN details.spj spj
	ON spj.s_id = s.s_id
LEFT JOIN details.p p
	ON p.p_id = spj.p_id
GROUP BY s.s_id, s.sname, p.color
ORDER BY s.s_id, p.color;

-- 10. Количество наименований деталей в заданных интервалах веса.
WITH intervals AS (
	SELECT lo, lo + 2 AS hi
	FROM generate_series(12, 18, 2) AS bins(lo)
)
SELECT
	'[' || i.lo || ', ' || i.hi || ')' AS weight_interval,
	count(p.p_id) AS part_count
FROM intervals i
LEFT JOIN details.p p
	ON p.weight >= i.lo
	AND p.weight < i.hi
GROUP BY i.lo, i.hi
ORDER BY i.lo;
