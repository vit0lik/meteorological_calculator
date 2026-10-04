-- ==========================================
-- БЛОК 1: ОСНОВНЫЕ ДАННЫЕ
-- ==========================================

-- 1.1 Генерация журнала измерений (logs: id 5–100)
INSERT INTO logs (id, user_id, equipment_id, measure_date)
SELECT 
    id,
    CASE 
        WHEN id BETWEEN 5 AND 23 THEN 1
        WHEN id BETWEEN 24 AND 42 THEN 2
        WHEN id BETWEEN 43 AND 61 THEN 3
        WHEN id BETWEEN 62 AND 80 THEN 4
        ELSE 5 
    END AS user_id,
    CASE WHEN id % 2 = 1 THEN 1 ELSE 2 END AS equipment_id,
    TIMESTAMP '2026-10-01 08:00:00' 
        + ((id - 5) / 14) * INTERVAL '1 day' 
        + ((id - 5) % 14) * INTERVAL '50 minutes' AS measure_date
FROM generate_series(5, 100) AS id;

-- 1.2 Генерация параметров (parameters: id 21–500)
INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value)
WITH param_seq AS (
    SELECT 
        p_id,
        5 + (p_id - 21) / 5 AS l_id,
        (p_id - 21) % 5 + 1 AS p_idx
    FROM generate_series(21, 500) AS p_id
),
param_types AS (
    SELECT 
        p_id,
        l_id,
        CASE 
            WHEN p_idx = 5 AND l_id % 2 = 0 THEN 6 
            ELSE p_idx 
        END AS p_type,
        -- Детерминированная высота метеопоста для текущей пачки
        40 + ((21 + (l_id - 5) * 5) * 17) % 261 AS calc_height
    FROM param_seq
)
SELECT 
    p_id AS id,
    l_id AS log_id,
    p_type AS parameter_type_id,
    CASE WHEN p_type = 6 THEN 1 ELSE p_type END AS unit_id,
    ROUND(CAST(CASE p_type
        WHEN 1 THEN calc_height
        WHEN 2 THEN -35.0 + ((p_id * 23) % 701) / 10.0
        WHEN 3 THEN 850.0 - (calc_height - 40.0) * (250.0 / 260.0)
        WHEN 4 THEN (p_id * 13) % 59
        WHEN 5 THEN (p_id * 7) % 13
        WHEN 6 THEN 20 + (p_id * 11) % 101
    END AS numeric), 1) AS value
FROM param_types;

-- ==========================================
-- БЛОК 2: НАМЕРЕННЫЕ ДЕФЕКТЫ (user_id = 5)
-- ==========================================

-- Добавление логов для дефектных пачек
INSERT INTO logs (id, user_id, equipment_id, measure_date) VALUES
    (101, 5, 1, '2026-10-08 09:00:00'), -- Лишняя пачка
    (102, 5, 1, '2026-10-08 10:00:00'), -- Пустая пачка
    (103, 5, 1, '2026-10-08 11:00:00'), -- Неполная пачка
    (104, 5, 2, '2026-10-08 12:00:00'), -- Выход за диапазон
    (105, 5, 1, '2026-10-08 13:00:00'); -- Некорректная единица измерения

-- 1. Лишняя пачка (logs id 101): параметры корректные
INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value) VALUES
    (501, 101, 1, 1, 150),
    (502, 101, 2, 2, 20.5),
    (503, 101, 3, 3, 750),
    (504, 101, 4, 4, 30),
    (505, 101, 5, 5, 5);

-- 2. Пустая пачка (logs id 102): записей в parameters нет (пропускаем вставку)

-- 3. Неполная пачка (logs id 103): пропущен параметр 4 (Направление ветра)
INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value) VALUES
    (506, 103, 1, 1, 160),
    (507, 103, 2, 2, 22.0),
    (508, 103, 3, 3, 740),
    (509, 103, 5, 5, 6);

-- 4. Выход за диапазон (logs id 104, ВР): высота (тип 1) = 6000 (лимит 5000)[cite: 2]
INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value) VALUES
    (510, 104, 1, 1, 6000), 
    (511, 104, 2, 2, 15.0),
    (512, 104, 3, 3, 800),
    (513, 104, 4, 4, 10),
    (514, 104, 6, 1, 50);

-- 5. Некорректная единица (logs id 105, ДМК): температура (тип 2) имеет unit_id = 5 (м/с вместо °C)
INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value) VALUES
    (515, 105, 1, 1, 140),
    (516, 105, 2, 5, 10.0), 
    (517, 105, 3, 3, 760),
    (518, 105, 4, 4, 25),
    (519, 105, 5, 5, 4);