\set ON_ERROR_STOP on
\pset pager off

SET bookings.lang = 'ru';

-- 2. Модели с дальностью от 4000 до 6000 км включительно.
SELECT
	airplane_code AS aircraft_code,
	model,
	range
FROM bookings.airplanes
WHERE range BETWEEN 4000 AND 6000
ORDER BY range, airplane_code;

-- 3. Места по модели и классу: все модели, включая модели без мест.
SELECT
	a.airplane_code AS aircraft_code,
	c.fare_conditions,
	count(s.seat_no) AS seat_count
FROM bookings.airplanes a
CROSS JOIN (
	VALUES
		('Business'),
		('Economy')
) AS c(fare_conditions)
LEFT JOIN bookings.seats s
	ON s.airplane_code = a.airplane_code
	AND s.fare_conditions = c.fare_conditions
GROUP BY a.airplane_code, c.fare_conditions
ORDER BY a.airplane_code, c.fare_conditions;

-- 7. Число маршрутов по типу самолета: внешнее соединение.
-- Один route_no может иметь несколько версий расписания.
SELECT
	a.airplane_code AS aircraft_code,
	a.model,
	count(DISTINCT r.route_no) AS route_count
FROM bookings.airplanes a
LEFT JOIN bookings.routes r
	ON r.airplane_code = a.airplane_code
GROUP BY a.airplane_code, a.model
ORDER BY a.airplane_code;

-- Тот же отчет с внутренним соединением.
SELECT
	a.airplane_code AS aircraft_code,
	a.model,
	count(DISTINCT r.route_no) AS route_count
FROM bookings.airplanes a
INNER JOIN bookings.routes r
	ON r.airplane_code = a.airplane_code
GROUP BY a.airplane_code, a.model
ORDER BY a.airplane_code;

-- 9. Отсутствие регистрации проверяется на конкретный перелет билета.
-- Считаем пассажиров, имеющих хотя бы один сегмент без посадочного талона.
SELECT
	count(DISTINCT t.passenger_id) AS unregistered_passengers,
	count(DISTINCT s.ticket_no) AS tickets_without_checkin,
	count(*) AS segments_without_checkin
FROM bookings.segments s
JOIN bookings.tickets t
	ON t.ticket_no = s.ticket_no
LEFT JOIN bookings.boarding_passes bp
	ON bp.ticket_no = s.ticket_no
	AND bp.flight_id = s.flight_id
WHERE bp.ticket_no IS NULL;

-- Дополнение: только уже вылетевшие рейсы, без будущей регистрации.
SELECT
	count(DISTINCT t.passenger_id) AS unregistered_passengers_on_departed_flights
FROM bookings.segments s
JOIN bookings.tickets t
	ON t.ticket_no = s.ticket_no
JOIN bookings.flights f
	ON f.flight_id = s.flight_id
LEFT JOIN bookings.boarding_passes bp
	ON bp.ticket_no = s.ticket_no
	AND bp.flight_id = s.flight_id
WHERE bp.ticket_no IS NULL
	AND f.actual_departure <= bookings.now();

-- 10. Общее число моделей в открытом интервале (0, 100000) км.
SELECT count(*) AS airplane_models
FROM bookings.airplanes
WHERE range > 0 AND range < 100000;

-- Аналог интервального отчета: шаг 10000 км, пустые интервалы сохраняются.
WITH intervals AS (
	SELECT lo, lo + 10000 AS hi
	FROM generate_series(0, 90000, 10000) AS bins(lo)
)
SELECT
	CASE WHEN i.lo = 0 THEN '(' ELSE '[' END
		|| i.lo || ', ' || i.hi || ')' AS range_interval_km,
	count(a.airplane_code) AS airplane_models
FROM intervals i
LEFT JOIN bookings.airplanes a
	ON a.range >= i.lo
	AND a.range < i.hi
	AND a.range > 0
	AND a.range < 100000
GROUP BY i.lo, i.hi
ORDER BY i.lo;
