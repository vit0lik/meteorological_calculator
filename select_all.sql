-- SELECT: объединение всех 5 таблиц

SELECT
    l.id AS log_id,
    l.measure_date,
    u.name AS user_name,
    r.name AS rank_name,
    e.name AS equipment_name,
    p.station_high,
    p.temperature,
    p.pressure,
    p.wind_direction,
    p.wind_speed,
    p.bullet_drift
FROM
    logs l
    INNER JOIN users u ON u.id = l.user_id
    INNER JOIN ranks r ON r.id = u.rank_id
    INNER JOIN equipment_types e ON e.id = l.equipment_id
    INNER JOIN parameters p ON p.id = l.parameter_id
ORDER BY
    l.id;