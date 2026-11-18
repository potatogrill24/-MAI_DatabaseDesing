\set ON_ERROR_STOP on
\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS documents;

CREATE TABLE IF NOT EXISTS documents.projects (
	project_id integer PRIMARY KEY,
	document jsonb NOT NULL,
	CHECK (jsonb_typeof(document) = 'object'),
	CHECK (document ?& ARRAY['title', 'status', 'tasks']),
	CHECK (jsonb_typeof(document -> 'title') = 'string'),
	CHECK (document ->> 'status' IN ('planned', 'active', 'completed')),
	CHECK (jsonb_typeof(document -> 'tasks') = 'array'),
	CHECK (
		NOT document ? 'priority'
		OR document ->> 'priority' IN ('low', 'normal', 'high')
	)
);

-- date — дата начала; duration_days — длительность задачи в днях.
-- Приоритет проекта наследуется его задачами; high — наивысший.
INSERT INTO documents.projects (project_id, document)
VALUES
	(
		1,
		'{
			"title": "Разработка базы",
			"priority": "high",
			"status": "completed",
			"tasks": [
				{"id": 1, "title": "Создать схему", "date": "2026-11-01", "duration_days": 2},
				{"id": 2, "title": "Написать запросы", "date": "2026-11-03", "duration_days": 3}
			]
		}'
	),
	(
		2,
		'{
			"title": "Подготовка отчета",
			"status": "active",
			"tasks": [
				{"id": 1, "title": "Описать результаты", "date": "2026-11-06", "duration_days": 4}
			]
		}'
	),
	(
		3,
		'{
			"title": "Проверка окружения",
			"priority": "normal",
			"status": "completed",
			"tasks": []
		}'
	)
ON CONFLICT (project_id) DO NOTHING;

-- Доп. 1. Только завершенные проекты.
SELECT project_id, document
FROM documents.projects
WHERE document ->> 'status' = 'completed'
ORDER BY project_id;

-- Доп. 2. Длительность каждого проекта и общий итог.
-- Здесь длительность проекта — сумма длительностей его задач.
WITH project_durations AS (
	SELECT
		p.project_id,
		p.document ->> 'title' AS title,
		coalesce(sum((t.task ->> 'duration_days')::integer), 0) AS duration_days
	FROM documents.projects p
	LEFT JOIN LATERAL jsonb_array_elements(p.document -> 'tasks') AS t(task)
		ON TRUE
	GROUP BY p.project_id, p.document ->> 'title'
)
SELECT
	project_id,
	title,
	duration_days,
	sum(duration_days) OVER () AS total_duration_days
FROM project_durations
ORDER BY project_id;

-- Доп. 3. Суммарная длительность задач с наивысшим приоритетом.
-- Отсутствующий приоритет проекта трактуется как normal.
SELECT
	coalesce(sum((t.task ->> 'duration_days')::integer), 0) AS high_priority_duration_days
FROM documents.projects p
CROSS JOIN LATERAL jsonb_array_elements(p.document -> 'tasks') AS t(task)
WHERE coalesce(p.document ->> 'priority', 'normal') = 'high';

COMMIT;
