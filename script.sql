-- DDL - Data Definition Language
DROP TABLE IF EXISTS logs;
DROP TABLE IF EXISTS parameters;
DROP TABLE IF EXISTS equipment_types;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS ranks;
CREATE TABLE ranks (
    id integer PRIMARY KEY,
    name varchar(100) NOT NULL
);
CREATE TABLE users (
    id integer PRIMARY KEY,
    name varchar(100) NOT NULL,
    rank_id integer NOT NULL
);
CREATE TABLE equipment_types (
    id integer PRIMARY KEY,
    name varchar(100) NOT NULL
);
CREATE TABLE parameters (
    id integer PRIMARY KEY,
    station_high integer NOT NULL,
    temperature numeric(4, 1) NOT NULL CHECK (
        temperature BETWEEN -58
        AND 58
    ),
    pressure integer NOT NULL CHECK (
        pressure BETWEEN 500
        AND 900
    ),
    wind_direction integer NOT NULL CHECK (
        wind_direction BETWEEN 0
        AND 59
    ),
    wind_speed integer CHECK (
        wind_speed BETWEEN 0
        AND 15
    ),
    bullet_drift integer CHECK (
        bullet_drift BETWEEN 0
        AND 150
    )
);
CREATE TABLE logs (
    id integer PRIMARY KEY,
    user_id integer NOT NULL,
    equipment_id integer NOT NULL,
    parameter_id integer NOT NULL,
    measure_date timestamp DEFAULT CURRENT_TIMESTAMP
);
-- DML - Data Manipulation Language
INSERT INTO
    ranks (id, name)
VALUES
    (1, 'Рядовой'),
    (2, 'Ефрейтор'),
    (3, 'Младший сержант'),
    (4, 'Сержант'),
    (5, 'Старший сержант'),
    (6, 'Старшина'),
    (7, 'Прапорщик'),
    (8, 'Старший прапорщик');
INSERT INTO
    users (id, name, rank_id)
VALUES
    (1, 'Волков Дмитрий Андреевич', 1),
    (2, 'Кузнецова Елена Игоревна', 3),
    (3, 'Смирнов Максим Витальевич', 2),
    (4, 'Морозова Анна Дмитриевна', 6),
    (5, 'Петров Роман Сергеевич', 5);
INSERT INTO
    equipment_types (id, name)
VALUES
    (1, 'ДМК'),
    (2, 'ВР');
-- ДМК: измеряется скорость ветра (wind_speed), снос пуль не заполняется
INSERT INTO
    parameters (
        id,
        station_high,
        temperature,
        pressure,
        wind_direction,
        wind_speed,
        bullet_drift
    )
VALUES
    (1, 150, 30.4, 700, 15, 12, NULL),
    (2, 160, 25.4, 654, 12, 9, NULL);
-- ВР: измеряется снос пуль, скорость ветра не заполняется
INSERT INTO
    parameters (
        id,
        station_high,
        temperature,
        pressure,
        wind_direction,
        wind_speed,
        bullet_drift
    )
VALUES
    (3, 50, 3.4, 720, 2, NULL, 25),
    (4, 60, 2.4, 554, 5, NULL, 30);
INSERT INTO
    logs (id, user_id, parameter_id, equipment_id)
VALUES
    (1, 1, 1, 1),
    (2, 2, 2, 1),
    (3, 3, 3, 2),
    (4, 4, 4, 2);