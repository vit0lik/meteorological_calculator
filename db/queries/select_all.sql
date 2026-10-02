-- Основной запрос: журнал измерений, одна строка = одно измерение
-- ANSI-92

SELECT
    l.measure_date AS "Дата измерения",
    l.id AS "Номер пачки",
    u.name AS "ФИО сотрудника",
    pt.name || ' (' || un.name || ')' AS "Наименование параметра и ед. измерения",
    p.value AS "Значение"
FROM
    logs l
    INNER JOIN users u ON u.id = l.user_id
    INNER JOIN parameters p ON p.log_id = l.id
    INNER JOIN parameter_types pt ON pt.id = p.parameter_type_id
    INNER JOIN units un ON un.id = p.unit_id
ORDER BY
    l.id,
    pt.id;
