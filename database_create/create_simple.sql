\set ON_ERROR_STOP on

-- Запускается через psql. При повторном запуске база simple пересоздается.
\connect postgres

DROP DATABASE IF EXISTS simple;
CREATE DATABASE simple;

\connect simple

SET client_encoding = 'UTF8';

BEGIN;

CREATE SCHEMA details;

-- Поставщики.
CREATE TABLE details.s (
	s_id char(2) NOT NULL,
	sname varchar(40),
	city varchar(40),
	PRIMARY KEY (s_id)
);

INSERT INTO details.s (s_id, sname, city)
VALUES
	('s1', 'Завод А', 'Москва'),
	('s2', 'Завод Б', 'Казань'),
	('s3', 'Завод В', 'Саратов'),
	('s4', 'Завод Г', 'Москва'),
	('s5', 'Завод Д', 'Самара');

-- Детали.
CREATE TABLE details.p (
	p_id char(2) NOT NULL,
	pname varchar(40),
	color varchar(40),
	weight numeric(7, 1),
	city varchar(40),
	PRIMARY KEY (p_id)
);

INSERT INTO details.p (p_id, pname, color, weight, city)
VALUES
	('p1', 'Болт', 'Красный', 12.0, 'Москва'),
	('p2', 'Винт', 'Синий', 17.0, 'Казань'),
	('p3', 'Валик', 'Красный', 17.0, 'Саратов'),
	('p4', 'Гайка', 'Белый', 14.0, 'Пермь'),
	('p5', 'Корпус', 'Синий', 12.0, 'Москва'),
	('p6', 'Кронштейн', 'Белый', 19.0, 'Пермь');

-- Проекты.
CREATE TABLE details.j (
	j_id char(2) NOT NULL,
	jname varchar(40),
	city varchar(40),
	PRIMARY KEY (j_id)
);

INSERT INTO details.j (j_id, jname, city)
VALUES
	('j1', 'Проект 1', 'Москва'),
	('j2', 'Проект 2', 'Пермь'),
	('j3', 'Проект 3', 'Саратов'),
	('j4', 'Проект 4', 'Москва'),
	('j5', 'Проект 5', 'Пермь'),
	('j6', 'Проект 6', 'Саратов'),
	('j7', 'Проект 7', 'Казань');

-- Поставки: поставщик, деталь, проект и количество.
-- Первичный ключ не добавляется: исходный набор содержит повторяющиеся строки.
CREATE TABLE details.spj (
	s_id char(2),
	p_id char(2),
	j_id char(2),
	qty int,
	FOREIGN KEY (s_id) REFERENCES details.s (s_id),
	FOREIGN KEY (p_id) REFERENCES details.p (p_id),
	FOREIGN KEY (j_id) REFERENCES details.j (j_id)
);

INSERT INTO details.spj (s_id, p_id, j_id, qty)
VALUES
	('s1', 'p1', 'j1', 200),
	('s1', 'p1', 'j4', 700),
	('s2', 'p3', 'j1', 400),
	('s2', 'p3', 'j2', 200),
	('s2', 'p3', 'j3', 200),
	('s2', 'p3', 'j4', 500),
	('s2', 'p3', 'j5', 600),
	('s2', 'p3', 'j6', 400),
	('s2', 'p3', 'j7', 800),
	('s2', 'p5', 'j2', 100),
	('s3', 'p3', 'j1', 200),
	('s3', 'p4', 'j2', 500),
	('s4', 'p6', 'j3', 300),
	('s4', 'p6', 'j7', 300),
	('s5', 'p2', 'j2', 200),
	('s5', 'p5', 'j4', 100),
	('s5', 'p5', 'j5', 500),
	('s5', 'p5', 'j7', 100),
	('s5', 'p6', 'j2', 200),
	('s5', 'p1', 'j4', 100),
	('s5', 'p3', 'j4', 200),
	('s5', 'p4', 'j4', 800),
	('s5', 'p5', 'j4', 400),
	('s5', 'p6', 'j4', 500),
	('s1', 'p1', 'j1', 200);

COMMIT;