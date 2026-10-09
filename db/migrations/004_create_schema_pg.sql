DO $$
BEGIN
    -- DDL (структура и счетчики)
    DROP TABLE IF EXISTS virtual_temperature_corrections, parameters, logs, 
                         parameter_types, units, base_units, users, ranks, equipment_types CASCADE;

    DROP SEQUENCE IF EXISTS virtual_temperature_corrections_seq, parameters_seq, logs_seq, 
                            parameter_types_seq, units_seq, base_units_seq, 
                            users_seq, ranks_seq, equipment_types_seq CASCADE;

    CREATE SEQUENCE base_units_seq START WITH 1;
    CREATE SEQUENCE units_seq START WITH 1;
    CREATE SEQUENCE ranks_seq START WITH 1;
    CREATE SEQUENCE users_seq START WITH 1;
    CREATE SEQUENCE equipment_types_seq START WITH 1;
    CREATE SEQUENCE parameter_types_seq START WITH 1;
    CREATE SEQUENCE logs_seq START WITH 1;
    CREATE SEQUENCE parameters_seq START WITH 1;
    CREATE SEQUENCE virtual_temperature_corrections_seq START WITH 1;

    CREATE TABLE base_units (
        id integer NOT NULL DEFAULT nextval('base_units_seq') PRIMARY KEY,
        name varchar(100) NOT NULL
    );

    CREATE TABLE units (
        id integer NOT NULL DEFAULT nextval('units_seq') PRIMARY KEY,
        base_unit_id integer NOT NULL,
        name varchar(100) NOT NULL,
        factor numeric(12, 3) NOT NULL
    );

    CREATE TABLE ranks (
        id integer NOT NULL DEFAULT nextval('ranks_seq') PRIMARY KEY,
        name varchar(100) NOT NULL
    );

    CREATE TABLE users (
        id integer NOT NULL DEFAULT nextval('users_seq') PRIMARY KEY,
        name varchar(100) NOT NULL,
        rank_id integer NOT NULL
    );

    CREATE TABLE equipment_types (
        id integer NOT NULL DEFAULT nextval('equipment_types_seq') PRIMARY KEY,
        code varchar(10) NOT NULL,
        name varchar(100) NOT NULL
    );

    CREATE TABLE parameter_types (
        id integer NOT NULL DEFAULT nextval('parameter_types_seq') PRIMARY KEY,
        name varchar(100) NOT NULL,
        default_unit_id integer NOT NULL,
        min_value numeric(10, 1) NOT NULL,
        max_value numeric(10, 1) NOT NULL
    );

    CREATE TABLE logs (
        id integer NOT NULL DEFAULT nextval('logs_seq') PRIMARY KEY,
        user_id integer NOT NULL,
        equipment_id integer NOT NULL,
        measure_date timestamptz DEFAULT now()
    );

    CREATE TABLE parameters (
        id integer NOT NULL DEFAULT nextval('parameters_seq') PRIMARY KEY,
        log_id integer NOT NULL,
        parameter_type_id integer NOT NULL,
        unit_id integer NOT NULL,
        value numeric(10, 1) NOT NULL
    );

    CREATE TABLE virtual_temperature_corrections (
        id integer NOT NULL DEFAULT nextval('virtual_temperature_corrections_seq') PRIMARY KEY,
        temp_from numeric(4, 1),
        temp_to numeric(4, 1) NOT NULL,
        correction numeric(3, 1) NOT NULL,
        description varchar(50) NOT NULL
    );

    ALTER SEQUENCE base_units_seq OWNED BY base_units.id;
    ALTER SEQUENCE units_seq OWNED BY units.id;
    ALTER SEQUENCE ranks_seq OWNED BY ranks.id;
    ALTER SEQUENCE users_seq OWNED BY users.id;
    ALTER SEQUENCE equipment_types_seq OWNED BY equipment_types.id;
    ALTER SEQUENCE parameter_types_seq OWNED BY parameter_types.id;
    ALTER SEQUENCE logs_seq OWNED BY logs.id;
    ALTER SEQUENCE parameters_seq OWNED BY parameters.id;
    ALTER SEQUENCE virtual_temperature_corrections_seq OWNED BY virtual_temperature_corrections.id;

    COMMIT;


    -- DML (данные)
    INSERT INTO base_units (id, name) VALUES
        (1, 'Метр'),
        (2, 'Градус Цельсия'),
        (3, 'Миллиметр ртутного столба'),
        (4, 'Большое деление угломера'),
        (5, 'Метр в секунду');

    INSERT INTO units (id, base_unit_id, name, factor) VALUES
        (1, 1, 'Метр', 1.000),
        (2, 2, 'Градус Цельсия', 1.000),
        (3, 3, 'Миллиметр ртутного столба', 1.000),
        (4, 4, 'Деление угломера (ДУ)', 1.000),
        (5, 5, 'Метр в секунду', 1.000);

    INSERT INTO equipment_types (id, code, name) VALUES
        (1, 'ДМК', 'Десантный метеокомплект'),
        (2, 'ВР',  'Ветровое ружье');

    INSERT INTO parameter_types (id, name, default_unit_id, min_value, max_value) VALUES
        (1, 'Высота метеопоста',     1, -1000.0, 5000.0),
        (2, 'Температура воздуха',   2,   -58.0,   58.0),
        (3, 'Атмосферное давление',  3,   500.0,  900.0),
        (4, 'Направление ветра',     4,     0.0,   59.0),
        (5, 'Скорость ветра',        5,     0.0,   15.0),
        (6, 'Дальность сноса пуль',  1,     0.0,  150.0);

    INSERT INTO ranks (id, name) VALUES
        (1, 'Рядовой'),
        (2, 'Сержант'),
        (3, 'Прапорщик');

    INSERT INTO users (id, name, rank_id) VALUES
        (1, 'Волков Дмитрий Андреевич', 1),
        (2, 'Кузнецова Елена Игоревна', 2);

    INSERT INTO virtual_temperature_corrections (id, temp_from, temp_to, correction, description) VALUES
        (1, NULL,  0.0, 0.0, 'Ниже 0'),
        (2,  0.0,  5.0, 0.5, '0 - 5'),
        (3, 10.0, 15.0, 1.0, '10 - 15'),
        (4, 20.0, 20.0, 1.5, '20'),
        (5, 25.0, 25.0, 2.0, '25'),
        (6, 30.0, 30.0, 3.5, '30'),
        (7, 40.0, 40.0, 4.5, '40');

    INSERT INTO logs (id, user_id, equipment_id, measure_date) VALUES
        (1, 1, 1, '2026-09-24 09:30:00+03'),
        (2, 2, 2, '2026-09-25 14:10:00+03');

    INSERT INTO parameters (id, log_id, parameter_type_id, unit_id, value) VALUES
        (1, 1, 1, 1, 100.0),
        (2, 1, 2, 2,  25.0),
        (3, 1, 3, 3, 765.0),
        (4, 1, 4, 4,  15.0),
        (5, 1, 5, 5,   6.0),
        (6, 2, 1, 1,  60.0),
        (7, 2, 2, 2,   3.0),
        (8, 2, 3, 3, 743.0),
        (9, 2, 4, 4,   2.0),
        (10, 2, 6, 1,  50.0);

    PERFORM setval('base_units_seq', (SELECT MAX(id) FROM base_units));
    PERFORM setval('units_seq', (SELECT MAX(id) FROM units));
    PERFORM setval('ranks_seq', (SELECT MAX(id) FROM ranks));
    PERFORM setval('users_seq', (SELECT MAX(id) FROM users));
    PERFORM setval('equipment_types_seq', (SELECT MAX(id) FROM equipment_types));
    PERFORM setval('parameter_types_seq', (SELECT MAX(id) FROM parameter_types));
    PERFORM setval('logs_seq', (SELECT MAX(id) FROM logs));
    PERFORM setval('parameters_seq', (SELECT MAX(id) FROM parameters));
    PERFORM setval('virtual_temperature_corrections_seq', (SELECT MAX(id) FROM virtual_temperature_corrections));

    COMMIT;


    -- Ограничения, FK, индексы и COMMENT ON
    ALTER TABLE units
        ADD CONSTRAINT chk_units_factor CHECK (factor > 0);

    ALTER TABLE parameter_types
        ADD CONSTRAINT chk_param_range CHECK (min_value <= max_value);

    ALTER TABLE equipment_types
        ADD CONSTRAINT uq_equipment_types_code UNIQUE (code);

    ALTER TABLE parameters
        ADD CONSTRAINT uq_parameters_log_param UNIQUE (log_id, parameter_type_id);

    ALTER TABLE units
        ADD CONSTRAINT fk_units_base_unit_id FOREIGN KEY (base_unit_id)
        REFERENCES base_units(id) ON DELETE RESTRICT;

    ALTER TABLE users
        ADD CONSTRAINT fk_users_rank_id FOREIGN KEY (rank_id)
        REFERENCES ranks(id) ON DELETE RESTRICT;

    ALTER TABLE parameter_types
        ADD CONSTRAINT fk_parameter_types_default_unit FOREIGN KEY (default_unit_id)
        REFERENCES units(id) ON DELETE RESTRICT;

    ALTER TABLE logs
        ADD CONSTRAINT fk_logs_user_id FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE RESTRICT,
        ADD CONSTRAINT fk_logs_equipment_id FOREIGN KEY (equipment_id)
        REFERENCES equipment_types(id) ON DELETE RESTRICT;

    ALTER TABLE parameters
        ADD CONSTRAINT fk_parameters_log_id FOREIGN KEY (log_id)
        REFERENCES logs(id) ON DELETE CASCADE,
        ADD CONSTRAINT fk_parameters_type_id FOREIGN KEY (parameter_type_id)
        REFERENCES parameter_types(id) ON DELETE RESTRICT,
        ADD CONSTRAINT fk_parameters_unit_id FOREIGN KEY (unit_id)
        REFERENCES units(id) ON DELETE RESTRICT;

    -- Индексы ключей для оптимизации поиска
    CREATE INDEX idx_units_base_unit_id ON units(base_unit_id);
    CREATE INDEX idx_users_rank_id ON users(rank_id);
    CREATE INDEX idx_parameter_types_default_unit ON parameter_types(default_unit_id);
    CREATE INDEX idx_logs_user_id ON logs(user_id);
    CREATE INDEX idx_logs_equipment_id ON logs(equipment_id);
    CREATE INDEX idx_parameters_log_id ON parameters(log_id);
    CREATE INDEX idx_parameters_type_id ON parameters(parameter_type_id);

    -- Комментарии к таблицам
    COMMENT ON TABLE base_units IS 'Базовые единицы измерения';
    COMMENT ON TABLE units IS 'Единицы измерения с коэффициентами пересчета';
    COMMENT ON TABLE ranks IS 'Воинские звания пользователей';
    COMMENT ON TABLE users IS 'Пользователи, проводящие измерения';
    COMMENT ON TABLE equipment_types IS 'Типы оборудования для измерения (ДМК, ВР)';
    COMMENT ON TABLE parameter_types IS 'Типы измеряемых параметров';
    COMMENT ON TABLE logs IS 'Журнал измерений';
    COMMENT ON TABLE parameters IS 'Измеренные параметры для каждого журнала';
    COMMENT ON TABLE virtual_temperature_corrections IS 'Таблица виртуальной поправки температуры';

    -- Комментарии к ключевым колонкам
    COMMENT ON COLUMN virtual_temperature_corrections.correction IS 'Величина виртуальной поправки';
    COMMENT ON COLUMN parameters.value IS 'Измеренное значение метеопараметра';
    COMMENT ON COLUMN logs.measure_date IS 'Время окончания зондирования атмосферы';

    COMMIT;
END $$;