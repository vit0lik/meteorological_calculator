-- 1. Проверка: у всех ли пользователей одинаковое количество пачек?
-- Ищет пользователей, у которых записей больше, чем у остальных
SELECT u.id, u.name, COUNT(l.id) AS log_count
FROM users u
LEFT JOIN logs l ON l.user_id = u.id
GROUP BY u.id, u.name
HAVING COUNT(l.id) > (
    SELECT MIN(c) 
    FROM (SELECT COUNT(id) AS c FROM logs GROUP BY user_id) AS sub
)
ORDER BY u.id;

-- 2. Проверка: есть ли пустые пачки без параметров?
-- Ищет записи logs, для которых нет строк в parameters
SELECT l.id, u.name
FROM logs l
JOIN users u ON l.user_id = u.id
WHERE NOT EXISTS (
    SELECT 1 FROM parameters p WHERE p.log_id = l.id
);

-- 3. Проверка: во всех ли пачках ровно по 5 параметров?
-- Ищет пачки, где количество измерений не равно 5
SELECT log_id, COUNT(*) AS param_count
FROM parameters
GROUP BY log_id
HAVING COUNT(*) <> 5
ORDER BY log_id;

-- 4. Проверка: все ли значения попадают в допустимый диапазон?
-- Ищет значения меньше min_value или больше max_value из справочника
SELECT 
    p.id,
    p.log_id,
    pt.name AS param_name,
    p.value,
    pt.min_value,
    pt.max_value
FROM parameters p
JOIN parameter_types pt ON p.parameter_type_id = pt.id
WHERE p.value NOT BETWEEN pt.min_value AND pt.max_value
ORDER BY p.log_id, p.id;

-- 5. Проверка: правильные ли единицы измерения у параметров?
-- Ищет строки, где unit_id не совпадает с default_unit_id из справочника
SELECT 
    p.id,
    p.log_id,
    pt.name AS param_name,
    p.unit_id AS actual_unit,
    pt.default_unit_id AS expected_unit
FROM parameters p
JOIN parameter_types pt ON p.parameter_type_id = pt.id
WHERE p.unit_id <> pt.default_unit_id
ORDER BY p.log_id, p.id;