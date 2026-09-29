-- DDL: Создание справочников

CREATE TABLE base_units (
    id integer PRIMARY KEY,
    name varchar(100) NOT NULL
);

CREATE TABLE units (
    id integer PRIMARY KEY,
    base_unit_id integer NOT NULL,
    name varchar(100) NOT NULL,
    factor numeric(12, 3) NOT NULL CHECK (
        factor > 0
    ),
    FOREIGN KEY (base_unit_id) REFERENCES base_units (
        id
    )
);

CREATE TABLE parameter_types (
    id integer PRIMARY KEY,
    name varchar(100) NOT NULL,
    default_unit_id integer NOT NULL,
    min_value numeric(10, 1) NOT NULL,
    max_value numeric(10, 1) NOT NULL,
    FOREIGN KEY (default_unit_id) REFERENCES units (
        id
    )
);


-- DML: Заполнение справочников

INSERT INTO
    base_units (id, name)
VALUES
    (1, 'Метр'),
    (2, 'Градус Цельсия'),
    (3, 'Миллиметр ртутного столба'),
    (4, 'Безразмерная единица'),
    (5, 'Метр в секунду');

INSERT INTO
    units (id, base_unit_id, name, factor)
VALUES
    (1, 1, 'Метр', 1.000),
    (2, 2, 'Градус Цельсия', 1.000),
    (3, 3, 'Миллиметр ртутного столба', 1.000),
    (4, 4, 'Деление угломера (десятисектор)', 1.000),
    (5, 5, 'Метр в секунду', 1.000);

INSERT INTO
    parameter_types (
        id,
        name,
        default_unit_id,
        min_value,
        max_value
    )
VALUES
    (1, 'Высота метеопоста', 1, -1000.0, 5000.0),
    (2, 'Температура воздуха', 2, -58.0, 58.0),
    (3, 'Атмосферное давление', 3, 500.0, 900.0),
    (4, 'Направление ветра', 4, 0.0, 59.0),
    (5, 'Скорость ветра', 5, 0.0, 15.0),
    (6, 'Дальность сноса пули', 1, 0.0, 150.0);


-- DDL: Подготовка таблицы parameters к новой структуре

ALTER TABLE parameters ADD COLUMN log_id integer;
ALTER TABLE parameters ADD COLUMN parameter_type_id integer;
ALTER TABLE parameters ADD COLUMN unit_id integer;
ALTER TABLE parameters ADD COLUMN value numeric(10, 1);

ALTER TABLE parameters ALTER COLUMN station_high DROP NOT NULL;
ALTER TABLE parameters ALTER COLUMN temperature DROP NOT NULL;
ALTER TABLE parameters ALTER COLUMN pressure DROP NOT NULL;
ALTER TABLE parameters ALTER COLUMN wind_direction DROP NOT NULL;
ALTER TABLE parameters ALTER COLUMN wind_speed DROP NOT NULL;
ALTER TABLE parameters ALTER COLUMN bullet_drift DROP NOT NULL;


-- DML: Миграция существующих данных

UPDATE parameters
SET
    log_id = id,
    parameter_type_id = 1,
    unit_id = 1,
    value = station_high;


INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value)
SELECT id + 4, id, 2, 2, temperature
FROM parameters WHERE temperature IS NOT NULL;

INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value)
SELECT id + 8, id, 3, 3, pressure
FROM parameters WHERE pressure IS NOT NULL;

INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value)
SELECT id + 12, id, 4, 4, wind_direction
FROM parameters WHERE wind_direction IS NOT NULL;

INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value)
SELECT id + 16, id, 5, 5, wind_speed
FROM parameters WHERE wind_speed IS NOT NULL;

INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value)
SELECT id + 16, id, 6, 1, bullet_drift
FROM parameters WHERE bullet_drift IS NOT NULL;


-- DDL: Удаление старых колонок и наложение ограничений

ALTER TABLE parameters DROP COLUMN station_high;
ALTER TABLE parameters DROP COLUMN temperature;
ALTER TABLE parameters DROP COLUMN pressure;
ALTER TABLE parameters DROP COLUMN wind_direction;
ALTER TABLE parameters DROP COLUMN wind_speed;
ALTER TABLE parameters DROP COLUMN bullet_drift;

ALTER TABLE parameters ALTER COLUMN log_id SET NOT NULL;
ALTER TABLE parameters ALTER COLUMN parameter_type_id SET NOT NULL;
ALTER TABLE parameters ALTER COLUMN unit_id SET NOT NULL;
ALTER TABLE parameters ALTER COLUMN value SET NOT NULL;

ALTER TABLE parameters ADD FOREIGN KEY (log_id) REFERENCES logs (
    id
);
ALTER TABLE parameters ADD FOREIGN KEY (parameter_type_id) REFERENCES parameter_types (
    id
);
ALTER TABLE parameters ADD FOREIGN KEY (unit_id) REFERENCES units (
    id
);

ALTER TABLE logs DROP COLUMN parameter_id;

-- DML: Обновление дат измерений

UPDATE logs SET measure_date = TIMESTAMP '2026-09-25 09:30:00' WHERE id = 1;
UPDATE logs SET measure_date = TIMESTAMP '2026-09-25 10:15:00' WHERE id = 2;
UPDATE logs SET measure_date = TIMESTAMP '2026-09-26 08:05:00' WHERE id = 3;
UPDATE logs SET measure_date = TIMESTAMP '2026-09-26 08:40:00' WHERE id = 4;

-- Комментарии

COMMENT ON TABLE base_units IS 'Базовые единицы измерения';
COMMENT ON TABLE units IS 'Единицы измерения';
COMMENT ON TABLE parameter_types IS 'Типы измеряемых параметров';
COMMENT ON COLUMN base_units.name IS 'Наименование базовой единицы';
COMMENT ON COLUMN units.base_unit_id IS 'Ссылка на базовую единицу измерения';
COMMENT ON COLUMN units.name IS 'Наименование единицы измерения';
COMMENT ON COLUMN units.factor IS 'Множитель приведения к базовой единице';
COMMENT ON COLUMN parameter_types.name IS 'Наименование типа параметра';
COMMENT ON COLUMN parameter_types.default_unit_id IS 'Единица измерения по умолчанию';
COMMENT ON COLUMN parameter_types.min_value IS 'Минимально допустимое значение';
COMMENT ON COLUMN parameter_types.max_value IS 'Максимально допустимое значение';
COMMENT ON COLUMN parameters.log_id IS 'Ссылка на пачку измерений';
COMMENT ON COLUMN parameters.parameter_type_id IS 'Ссылка на тип параметра';
COMMENT ON COLUMN parameters.unit_id IS 'Ссылка на единицу измерения';
COMMENT ON COLUMN parameters.value IS 'Измеренное значение';
