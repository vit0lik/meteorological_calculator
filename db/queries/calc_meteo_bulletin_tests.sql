-- ДМК (t0 = 25, wind = 6, dir = 15)
CALL calc_meteo_bulletin(ROW('ДМК', 100, 25, 765, 15, 6, NULL)::meteo_param_list, 1);
SELECT 'ДМК (t=25)' AS "test", * FROM temp_meteo_result ORDER BY height_m;

-- ДМК с отрицательной температурой (t0 = 3)
CALL calc_meteo_bulletin(ROW('ДМК', 100, 3, 750, 0, 0, NULL)::meteo_param_list, 1);
SELECT 'ДМК (t=3)' AS "test", * FROM temp_meteo_result ORDER BY height_m;

-- ВР (Снос = 80)
CALL calc_meteo_bulletin(ROW('ВР', 100, 15, 750, 10, NULL, 80)::meteo_param_list, 2);
SELECT 'ВР (drift=80)' AS "test", * FROM temp_meteo_result ORDER BY height_m;