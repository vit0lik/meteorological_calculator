WITH pivoted_logs AS (
    SELECT 
        l.id AS log_id,
        et.code AS equipment_code,
        et.name AS equipment_name,
        MAX(CASE WHEN p.parameter_type_id = 1 THEN p.value END) AS height,
        MAX(CASE WHEN p.parameter_type_id = 2 THEN p.value END) AS temperature,
        MAX(CASE WHEN p.parameter_type_id = 3 THEN p.value END) AS pressure,
        MAX(CASE WHEN p.parameter_type_id = 4 THEN p.value END) AS wind_dir,
        MAX(CASE WHEN p.parameter_type_id = 5 THEN p.value END) AS wind_speed,
        MAX(CASE WHEN p.parameter_type_id = 6 THEN p.value END) AS bullet_drift
    FROM logs l
    JOIN equipment_types et ON l.equipment_id = et.id
    LEFT JOIN parameters p ON p.log_id = l.id
    GROUP BY l.id, et.code, et.name
),
validated_logs AS (
    SELECT 
        pl.*,
        validate_meteo_params(
            ROW(
                pl.equipment_code,
                pl.height,
                pl.temperature,
                pl.pressure,
                pl.wind_dir,
                pl.wind_speed,
                pl.bullet_drift
            )::meteo_param_list
        ) AS error_text
    FROM pivoted_logs pl
)
SELECT 
    log_id AS "№",
    equipment_name AS "Тип оборудования",
    height AS "Высота метеопоста",
    temperature AS "Температура",
    pressure AS "Давление",
    wind_dir AS "Направление ветра",
    wind_speed AS "Скорость ветра",
    bullet_drift AS "Дальность сноса пуль",
    (error_text IS NOT NULL) AS "Флаг: Есть ошибка",
    COALESCE(error_text, 'Ошибок нет') AS "Описание ошибки"
FROM validated_logs
ORDER BY log_id;