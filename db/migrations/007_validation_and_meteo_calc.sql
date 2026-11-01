DO $$
BEGIN
    -- 1: Расширение DDL таблицы параметров информацией об ошибках
    BEGIN
        BEGIN
            ALTER TABLE parameter_types
                ADD COLUMN error_message varchar(255);
        EXCEPTION
            WHEN duplicate_column THEN NULL;
        END;

        UPDATE parameter_types SET error_message = 'Высота метеопоста вне диапазона [-1000; 5000]' WHERE id = 1;
        UPDATE parameter_types SET error_message = 'Температура воздуха вне диапазона [-58; 58]' WHERE id = 2;
        UPDATE parameter_types SET error_message = 'Атмосферное давление вне диапазона [500; 900]' WHERE id = 3;
        UPDATE parameter_types SET error_message = 'Направление ветра вне диапазона [0; 59]' WHERE id = 4;
        UPDATE parameter_types SET error_message = 'Скорость ветра вне диапазона [0; 15]' WHERE id = 5;
        UPDATE parameter_types SET error_message = 'Дальность сноса пуль вне диапазона [0; 150]' WHERE id = 6;

        ALTER TABLE parameter_types
            ALTER COLUMN error_message SET NOT NULL;

        COMMENT ON COLUMN parameter_types.error_message IS 'Текст ошибки при выходе значения за допустимый диапазон';
    END;

    -- 2: Составной тип данных для списка входных параметров
    BEGIN
        CREATE TYPE meteo_param_list AS (
            equipment_code varchar(10),
            height numeric(10, 1),
            temperature numeric(10, 1),
            pressure numeric(10, 1),
            wind_dir numeric(10, 1),
            wind_speed numeric(10, 1),
            bullet_drift numeric(10, 1)
        );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;

    COMMENT ON TYPE meteo_param_list IS 'Составной тип со списком входных метеопараметров';

    -- 3: Функция проверки корректности параметров
    BEGIN
        CREATE OR REPLACE FUNCTION validate_meteo_params(p_params meteo_param_list)
        RETURNS text
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            v_errors text;
        BEGIN
            WITH input_values AS (
                SELECT 1 AS type_id, p_params.height AS val
                UNION ALL SELECT 2, p_params.temperature
                UNION ALL SELECT 3, p_params.pressure
                UNION ALL SELECT 4, p_params.wind_dir
                UNION ALL SELECT 5, p_params.wind_speed WHERE p_params.equipment_code = 'ДМК'
                UNION ALL SELECT 6, p_params.bullet_drift WHERE p_params.equipment_code = 'ВР'
            )
            SELECT STRING_AGG(pt.error_message, '; ')
            INTO v_errors
            FROM input_values iv
            JOIN parameter_types pt ON pt.id = iv.type_id
            WHERE iv.val IS NULL 
               OR iv.val < pt.min_value 
               OR iv.val > pt.max_value;

            RETURN v_errors;
        END;
        $func$;

        COMMENT ON FUNCTION validate_meteo_params(meteo_param_list) IS 'Проверка входных параметров на соответствие диапазонам с возвратом списка ошибок';
    END;

    -- 4: Функции расчета групп Метео приближенный
    BEGIN
        CREATE OR REPLACE FUNCTION calc_meteo_ddhhm(p_date timestamptz DEFAULT now())
        RETURNS varchar(5)
        LANGUAGE plpgsql
        AS $func$
        BEGIN
            RETURN SUBSTRING(TO_CHAR(p_date, 'DDHH24MI'), 1, 5);
        END;
        $func$;

        CREATE OR REPLACE FUNCTION calc_meteo_vvvv(p_height numeric)
        RETURNS varchar(4)
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            v_h integer := ROUND(p_height)::integer;
        BEGIN
            -- IF v_h < 0 THEN
            --     RETURN '-' || LPAD(ABS(v_h)::text, 3, '0');
            -- END IF;
            RETURN LPAD(v_h::text, 4, '0');
        END;
        $func$;

        CREATE OR REPLACE FUNCTION calc_meteo_bbbtt(p_pressure numeric, p_temp numeric)
        RETURNS varchar(5)
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            v_std_press numeric := get_meteo_constant(1);
            v_std_temp numeric := get_meteo_constant(2);
            v_neg_press numeric := get_meteo_constant(3);
            v_neg_temp numeric := get_meteo_constant(4);
            
            v_delta_h integer;
            v_bbb varchar(3);
            
            v_tv_corr numeric;
            v_t0 numeric;
            v_delta_t integer;
            v_tt varchar(2);
        BEGIN
            v_delta_h := ROUND(p_pressure - v_std_press)::integer;
            IF v_delta_h < 0 THEN
                v_bbb := LPAD((ABS(v_delta_h) + v_neg_press::integer)::text, 3, '0');
            ELSE
                v_bbb := LPAD(v_delta_h::text, 3, '0');
            END IF;

            v_tv_corr := calculate_interpolation(p_temp, get_interpolation_params(p_temp));
            v_t0 := p_temp + v_tv_corr;
            v_delta_t := ROUND(v_t0 - v_std_temp)::integer;

            IF v_delta_t < 0 THEN
                v_tt := LPAD((ABS(v_delta_t) + v_neg_temp::integer)::text, 2, '0');
            ELSE
                v_tt := LPAD(v_delta_t::text, 2, '0');
            END IF;

            RETURN v_bbb || v_tt;
        END;
        $func$;

        COMMENT ON FUNCTION calc_meteo_ddhhm(timestamptz) IS 'Формирование группы ДДЧЧМ (день, часы, десятки минут)';
        COMMENT ON FUNCTION calc_meteo_vvvv(numeric) IS 'Формирование группы ВВВВ (высота метеопоста)';
        COMMENT ON FUNCTION calc_meteo_bbbtt(numeric, numeric) IS 'Формирование группы БББТТ (отклонение давления и температуры)';
    END;

    -- 5: Тестовые пачки с ошибками
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM logs WHERE id = 3) THEN
            INSERT INTO logs (user_id, equipment_id, measure_date) VALUES
                (1, 1, '2026-09-26 10:20:00+03'),
                (2, 2, '2026-09-26 11:00:00+03');

            INSERT INTO parameters (log_id, parameter_type_id, unit_id, value) VALUES
                (3, 1, 1,  6000.0), -- Ошибка типа 1: Высота > 5000
                (3, 2, 2,    65.0), -- Ошибка типа 2: Температура > 58
                (3, 3, 3,   450.0), -- Ошибка типа 3: Давление < 500
                (3, 4, 4,    70.0), -- Ошибка типа 4: Направление ветра > 59
                (3, 5, 5,    25.0), -- Ошибка типа 5: Скорость ветра > 15
                (4, 1, 1, -1500.0), -- Ошибка типа 1: Высота < -1000
                (4, 2, 2,   -60.0), -- Ошибка типа 2: Температура < -58
                (4, 3, 3,   950.0), -- Ошибка типа 3: Давление > 900
                (4, 4, 4,    -5.0), -- Ошибка типа 4: Направление ветра < 0
                (4, 6, 1,   200.0); -- Ошибка типа 6: Дальность сноса пуль > 150
        END IF;
    END;

    COMMIT;
END $$;