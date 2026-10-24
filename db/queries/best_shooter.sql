WITH pivoted_logs AS (
    SELECT 
        l.user_id,
        et.code,
        MAX(CASE WHEN p.parameter_type_id = 1 THEN p.value END) h,
        MAX(CASE WHEN p.parameter_type_id = 2 THEN p.value END) t,
        MAX(CASE WHEN p.parameter_type_id = 3 THEN p.value END) press,
        MAX(CASE WHEN p.parameter_type_id = 4 THEN p.value END) wd,
        MAX(CASE WHEN p.parameter_type_id = 5 THEN p.value END) ws,
        MAX(CASE WHEN p.parameter_type_id = 6 THEN p.value END) bd
    FROM logs l
    JOIN equipment_types et ON l.equipment_id = et.id
    LEFT JOIN parameters p ON p.log_id = l.id
    GROUP BY l.id, l.user_id, et.code
)
SELECT 
    u.name "Пользователь",
    COALESCE(SUM(REGEXP_COUNT(validate_meteo_params((code, h, t, press, wd, ws, bd)), 'диапазона')), 0) "Количество ошибок",
    RANK() OVER (ORDER BY COALESCE(SUM(REGEXP_COUNT(validate_meteo_params((code, h, t, press, wd, ws, bd)), '[^;]+')), 0)) "Место"
FROM users u
LEFT JOIN pivoted_logs pl ON pl.user_id = u.id
GROUP BY u.id, u.name
ORDER BY "Место";