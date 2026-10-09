-- Таблицы
SELECT 
    table_name AS "Наименование",
    'Таблица' AS "Тип"
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'

UNION ALL

-- Счетчики
SELECT 
    sequence_name AS "Наименование",
    'Счетчик' AS "Тип"
FROM information_schema.sequences
WHERE sequence_schema = 'public';
