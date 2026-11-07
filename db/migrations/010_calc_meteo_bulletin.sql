DO $$
BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION get_correction_val(p_type_id int, p_height_id int, p_column_val int)
        RETURNS integer LANGUAGE sql AS $func$
            SELECT c.row_values[u.i]
            FROM calc_correction c
            JOIN calc_correction_types t ON t.id = c.type_id
            LEFT JOIN calc_correction_types p ON p.id = t.parent_id
            JOIN calc_correction_headers h ON h.id = COALESCE(t.header_id, p.header_id)
            JOIN LATERAL unnest(h.header_values) WITH ORDINALITY AS u(val, i) ON u.val = p_column_val
            WHERE c.type_id = p_type_id AND c.height_id = p_height_id
            LIMIT 1;
        $func$;

        CREATE OR REPLACE FUNCTION get_wind_speed_val(p_type_id int, p_height_id int, p_column_val int)
        RETURNS integer LANGUAGE sql AS $func$
            SELECT c.row_values[u.i]
            FROM calc_correction c
            JOIN calc_correction_types t ON t.id = c.type_id
            JOIN calc_correction_headers h ON h.id = t.header_id
            JOIN LATERAL unnest(h.header_values) WITH ORDINALITY AS u(val, i) ON true
            WHERE c.type_id = p_type_id AND c.height_id = p_height_id
            ORDER BY abs(u.val - p_column_val), u.val
            LIMIT 1;
        $func$;
    END;

    BEGIN
        CREATE OR REPLACE PROCEDURE calc_meteo_bulletin(
            p_params meteo_param_list,
            p_equipment_id integer
        )
        LANGUAGE plpgsql AS $proc$
        DECLARE
            v_errors text;
            v_delta_t integer;
            v_temp_type integer;
            v_speed_type integer;
            v_dir_type integer;
            v_wind_input numeric;
            v_is_calm boolean;
        BEGIN
            -- 1. Валидация входных параметров
            v_errors := validate_meteo_params(p_params);
            IF v_errors IS NOT NULL AND v_errors != '' THEN
                RAISE EXCEPTION 'Ошибка валидации параметров: %', v_errors;
            END IF;

            -- 2. Расчет дельты температуры
            v_delta_t := ROUND((p_params.temperature + calculate_interpolation(p_params.temperature, get_interpolation_params(p_params.temperature)) - 15.9)::numeric)::integer;
            
            -- Ограничение дельты температуры (Clamp) до диапазона заголовков таблицы 2 [-50, 50],
            -- чтобы избежать вылета по отсутствующей колонке и формата ТТ > 99
            IF v_delta_t > 50 THEN v_delta_t := 50; END IF;
            IF v_delta_t < -50 THEN v_delta_t := -50; END IF;

            v_temp_type := CASE WHEN v_delta_t < 0 THEN 9 ELSE 8 END;

            -- 3. Настройка параметров ветра
            IF p_equipment_id = 1 THEN
                v_speed_type := 6;
                v_dir_type := 7;
                v_wind_input := COALESCE(p_params.wind_speed, 0);
                v_is_calm := v_wind_input < 3;
            ELSE
                v_speed_type := 4;
                v_dir_type := 5;
                v_wind_input := COALESCE(p_params.bullet_drift, 0);
                v_is_calm := v_wind_input < 40;
            END IF;

            DROP TABLE IF EXISTS temp_meteo_result;
            CREATE TEMP TABLE temp_meteo_result(height_m integer, tt text, hh text, cc text);

            -- 4. Формирование результатов
            INSERT INTO temp_meteo_result(height_m, tt, hh, cc)
            SELECT 
                sh.height_m,
                LPAD((CASE WHEN v_delta_t < 0 THEN 50 + abs(x.corr) ELSE x.corr END)::text, 2, '0') AS tt,
                CASE WHEN v_is_calm THEN '00' 
                     ELSE LPAD(MOD(COALESCE(p_params.wind_dir, 0)::integer + 
                          (SELECT row_values[1] FROM calc_correction WHERE type_id = v_dir_type AND height_id = sh.id), 60)::text, 2, '0')
                END AS hh,
                CASE WHEN v_is_calm THEN '00' 
                     ELSE LPAD(get_wind_speed_val(v_speed_type, sh.id, v_wind_input::integer)::text, 2, '0')
                END AS cc
            FROM standard_heights sh
            CROSS JOIN LATERAL (
                SELECT 
                    COALESCE(CASE WHEN (abs(v_delta_t) / 10) * 10 > 0 
                                  THEN get_correction_val(v_temp_type, sh.id, (abs(v_delta_t) / 10) * 10) 
                                  ELSE 0 END, 0) +
                    COALESCE(CASE WHEN abs(v_delta_t) % 10 > 0 
                                  THEN get_correction_val(v_temp_type, sh.id, abs(v_delta_t) % 10) 
                                  ELSE 0 END, 0) AS corr
            ) x
            ORDER BY sh.height_m;
        END;
        $proc$;

        COMMENT ON PROCEDURE calc_meteo_bulletin(meteo_param_list, integer) IS 'Процедура расчета бюллетеня "Метео-средний"';
    END;
END $$;