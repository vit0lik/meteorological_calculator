-- Скрипт миграции №2, выполняется после script.sql

-- DDL - Data Definition Language

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

-- DML - Data Manipulation Language

INSERT INTO
    base_units (id, name)
VALUES
    (1, 'Метр'),
    (2, 'Градус Цельсия'),
    (3, 'Миллиметр ртутного столба'),
    (4, 'Метр в секунду'),
    (5, 'Безразмерная единица');

INSERT INTO
    units (id, base_unit_id, name, factor)
VALUES
    (1, 1, 'Метр', 1),
    (3, 2, 'Градус Цельсия', 1),
    (4, 3, 'Миллиметр ртутного столба', 1),
    (5, 4, 'Метр в секунду', 1),
    (6, 5, 'Деление угломера (десятисектор)', 1);

INSERT INTO
    parameter_types (
        id,
        name,
        default_unit_id,
        min_value,
        max_value
    )
VALUES
    (1, 'Высота метеопоста', 1, -1000, 5000),
    (2, 'Температура воздуха', 3, -58, 58),
    (3, 'Атмосферное давление', 4, 500, 900),
    (4, 'Направление ветра', 6, 0, 59),
    (5, 'Скорость ветра', 5, 0, 15),
    (6, 'Дальность сноса пули', 1, 0, 150);

-- DML - освобождение parameters перед изменением структуры

DELETE FROM parameters;

UPDATE logs SET measure_date = TIMESTAMP '2026-09-25 09:30:00' WHERE id = 1;
UPDATE logs SET measure_date = TIMESTAMP '2026-09-25 10:15:00' WHERE id = 2;
UPDATE logs SET measure_date = TIMESTAMP '2026-09-26 08:05:00' WHERE id = 3;
UPDATE logs SET measure_date = TIMESTAMP '2026-09-26 08:40:00' WHERE id = 4;

-- DDL - parameters становится таблицей измерений: одна строка - одно значение

ALTER TABLE parameters DROP COLUMN station_high;
ALTER TABLE parameters DROP COLUMN temperature;
ALTER TABLE parameters DROP COLUMN pressure;
ALTER TABLE parameters DROP COLUMN wind_direction;
ALTER TABLE parameters DROP COLUMN wind_speed;
ALTER TABLE parameters DROP COLUMN bullet_drift;

ALTER TABLE parameters ADD COLUMN log_id integer NOT NULL;
ALTER TABLE parameters ADD COLUMN parameter_type_id integer NOT NULL;
ALTER TABLE parameters ADD COLUMN unit_id integer NOT NULL;
ALTER TABLE parameters ADD COLUMN value numeric(10, 1) NOT NULL;
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

-- DML - перенос измерений из скрипта №1 в новую структуру

INSERT INTO
    parameters (
        id,
        log_id,
        parameter_type_id,
        unit_id,
        value
    )
VALUES
    (1, 1, 1, 1, 150.0),
    (2, 1, 2, 3, 30.4),
    (3, 1, 3, 4, 700.0),
    (4, 1, 4, 6, 15.0),
    (5, 1, 5, 5, 12.0);

INSERT INTO
    parameters (
        id,
        log_id,
        parameter_type_id,
        unit_id,
        value
    )
VALUES
    (6, 2, 1, 1, 160.0),
    (7, 2, 2, 3, 25.4),
    (8, 2, 3, 4, 654.0),
    (9, 2, 4, 6, 12.0),
    (10, 2, 5, 5, 9.0);

INSERT INTO
    parameters (
        id,
        log_id,
        parameter_type_id,
        unit_id,
        value
    )
VALUES
    (11, 3, 1, 1, 50.0),
    (12, 3, 2, 3, 3.4),
    (13, 3, 3, 4, 720.0),
    (14, 3, 4, 6, 2.0),
    (15, 3, 6, 1, 25.0);

INSERT INTO
    parameters (
        id,
        log_id,
        parameter_type_id,
        unit_id,
        value
    )
VALUES
    (16, 4, 1, 1, 60.0),
    (17, 4, 2, 3, 2.4),
    (18, 4, 3, 4, 554.0),
    (19, 4, 4, 6, 5.0),
    (20, 4, 6, 1, 30.0);


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
