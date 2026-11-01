DO $$
BEGIN
    -- Справочник стандартных высот (общее для таблиц 2 и 3)
    BEGIN
        CREATE SEQUENCE IF NOT EXISTS standard_heights_seq START WITH 1;

        CREATE TABLE IF NOT EXISTS standard_heights (
            id integer NOT NULL DEFAULT nextval('standard_heights_seq') PRIMARY KEY,
            height_m integer NOT NULL UNIQUE CHECK (height_m > 0)
        );

        ALTER SEQUENCE standard_heights_seq OWNED BY standard_heights.id;

        IF NOT EXISTS (SELECT 1 FROM standard_heights) THEN
            INSERT INTO standard_heights (height_m) VALUES
                (200), (400), (800), (1200), (1600), (2000), (2400), (3000), (4000);
        END IF;

        COMMENT ON TABLE standard_heights IS 'Справочник стандартных высот';
        COMMENT ON COLUMN standard_heights.id IS 'Идентификатор высоты';
        COMMENT ON COLUMN standard_heights.height_m IS 'Значение стандартной высоты в метрах';
    END;

    -- Таблица 2 (Средние отклонения температуры воздуха на стандартных высотах)
    BEGIN
        CREATE SEQUENCE IF NOT EXISTS temp_deviation_seq START WITH 1;

        CREATE TABLE IF NOT EXISTS temp_deviation (
            id integer NOT NULL DEFAULT nextval('temp_deviation_seq') PRIMARY KEY,
            height_id integer NOT NULL REFERENCES standard_heights(id) ON DELETE CASCADE,
            ground_temp_delta integer NOT NULL CHECK (ground_temp_delta IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40)),
            neg_deviation integer NOT NULL,
            pos_deviation integer NOT NULL,
            UNIQUE (height_id, ground_temp_delta)
        );

        ALTER SEQUENCE temp_deviation_seq OWNED BY temp_deviation.id;

        COMMENT ON TABLE temp_deviation IS 'Средние отклонения температуры воздуха для стандартных высот';
        COMMENT ON COLUMN temp_deviation.id IS 'Идентификатор записи';
        COMMENT ON COLUMN temp_deviation.height_id IS 'Ссылка на стандартную высоту';
        COMMENT ON COLUMN temp_deviation.ground_temp_delta IS 'Отклонение приземной виртуальной температуры на земле';
        COMMENT ON COLUMN temp_deviation.neg_deviation IS 'Среднее отклонение для отрицательных значений';
        COMMENT ON COLUMN temp_deviation.pos_deviation IS 'Среднее отклонение для положительных значений';
    END;

    -- Таблица 3 (Приращения направления и скорость среднего ветра для ДМК и ВР)
    BEGIN
        CREATE SEQUENCE IF NOT EXISTS wind_corrections_seq START WITH 1;

        CREATE TABLE IF NOT EXISTS wind_corrections (
            id integer NOT NULL DEFAULT nextval('wind_corrections_seq') PRIMARY KEY,
            equipment_id integer NOT NULL REFERENCES equipment_types(id) ON DELETE CASCADE,
            unit_id integer NOT NULL REFERENCES base_units(id) ON DELETE RESTRICT,
            height_id integer NOT NULL REFERENCES standard_heights(id) ON DELETE CASCADE,
            input_value integer NOT NULL CHECK (input_value > 0),
            dir_increment integer NOT NULL,
            avg_wind_speed integer NOT NULL,
            UNIQUE (equipment_id, height_id, input_value)
        );

        ALTER SEQUENCE wind_corrections_seq OWNED BY wind_corrections.id;

        COMMENT ON TABLE wind_corrections IS 'Приращения направления и скорость среднего ветра';
        COMMENT ON COLUMN wind_corrections.id IS 'Идентификатор записи';
        COMMENT ON COLUMN wind_corrections.equipment_id IS 'Ссылка на тип оборудования (ДМК / ВР)';
        COMMENT ON COLUMN wind_corrections.unit_id IS 'Ссылка на единицу измерения входного параметра';
        COMMENT ON COLUMN wind_corrections.height_id IS 'Ссылка на стандартную высоту';
        COMMENT ON COLUMN wind_corrections.input_value IS 'Значение входного параметра на земле';
        COMMENT ON COLUMN wind_corrections.dir_increment IS 'Приращение направления среднего ветра';
        COMMENT ON COLUMN wind_corrections.avg_wind_speed IS 'Скорость среднего ветра';
    END;

    COMMIT;
END $$;