DO $$
BEGIN
    -- 1: Структура таблицы для хранения констант
    BEGIN
        CREATE SEQUENCE IF NOT EXISTS meteo_constants_seq START WITH 1;

        CREATE TABLE IF NOT EXISTS meteo_constants (
            id integer NOT NULL DEFAULT nextval('meteo_constants_seq') PRIMARY KEY,
            name varchar(150) NOT NULL,
            value numeric(10, 2) NOT NULL
        );

        ALTER SEQUENCE meteo_constants_seq OWNED BY meteo_constants.id;

        COMMENT ON TABLE meteo_constants IS 'Справочник констант для метеорологических расчетов';
        COMMENT ON COLUMN meteo_constants.id IS 'Идентификатор константы';
        COMMENT ON COLUMN meteo_constants.name IS 'Описание константы';
        COMMENT ON COLUMN meteo_constants.value IS 'Числовое значение константы';
    END;

    -- 2: Заполнение справочника констант
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM meteo_constants) THEN
            INSERT INTO meteo_constants (name, value) VALUES
                ('Табличное значение наземного давления (мм рт. ст.)', 750.00),     -- id = 1
                ('Табличное значение приземной виртуальной температуры (°C)', 15.90), -- id = 2
                ('Кодировка знака минус для отклонения давления (БББ)', 500.00),     -- id = 3
                ('Кодировка знака минус для отклонения температуры (ТТ)', 50.00);    -- id = 4
        END IF;
    END;

    -- 3: Составной тип с набором констант
    BEGIN
        CREATE TYPE meteo_constants_type AS (
            std_pressure numeric(10, 2),
            std_temp numeric(10, 2),
            neg_pressure_offset integer,
            neg_temp_offset integer
        );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;

    COMMENT ON TYPE meteo_constants_type IS 'Структура расчетных констант для Метео-11';

    -- 4: Функции для получения констант
    BEGIN
        CREATE OR REPLACE FUNCTION get_meteo_constant(p_id integer)
        RETURNS numeric
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            v_val numeric;
        BEGIN
            SELECT value INTO v_val
            FROM meteo_constants
            WHERE id = p_id;

            RETURN v_val;
        END;
        $func$;

        CREATE OR REPLACE FUNCTION get_all_meteo_constants()
        RETURNS meteo_constants_type
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            v_consts meteo_constants_type;
        BEGIN
            v_consts.std_pressure := get_meteo_constant(1);
            v_consts.std_temp := get_meteo_constant(2);
            v_consts.neg_pressure_offset := get_meteo_constant(3)::integer;
            v_consts.neg_temp_offset := get_meteo_constant(4)::integer;

            RETURN v_consts;
        END;
        $func$;

        COMMENT ON FUNCTION get_meteo_constant(integer) IS 'Получение значения константы по идентификатору';
        COMMENT ON FUNCTION get_all_meteo_constants() IS 'Получение структуры со всеми расчетными константами';
    END;

    COMMIT;
END $$;