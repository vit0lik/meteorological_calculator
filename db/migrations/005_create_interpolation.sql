DO $$
BEGIN
    -- Создание типа данных для интерполяции (x0, y0, x1, y1)
    BEGIN
        CREATE TYPE interpolation_params AS (
            x0 numeric(4, 1),
            y0 numeric(3, 1),
            x1 numeric(4, 1),
            y1 numeric(3, 1)
        );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;

    COMMIT;

    -- Функция определения параметров для интерполяции по температуре
    CREATE OR REPLACE FUNCTION get_interpolation_params(p_temp numeric)
    RETURNS interpolation_params
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_params interpolation_params;
    BEGIN
        IF p_temp < 0 THEN
            RETURN ROW(p_temp, 0.0, p_temp, 0.0)::interpolation_params;
        END IF;

        SELECT temp, correction
        INTO v_params.x0, v_params.y0
        FROM virtual_temperature_corrections
        WHERE temp <= p_temp
        ORDER BY temp DESC
        LIMIT 1;

        SELECT temp, correction
        INTO v_params.x1, v_params.y1
        FROM virtual_temperature_corrections
        WHERE temp >= p_temp
        ORDER BY temp ASC
        LIMIT 1;

        IF v_params.x1 IS NULL THEN
            v_params.x1 := p_temp;
            v_params.y1 := v_params.y0;
        END IF;

        IF v_params.x0 IS NULL THEN
            v_params.x0 := p_temp;
            v_params.y0 := v_params.y1;
        END IF;

        RETURN v_params;
    END;
    $func$;

    -- Функция расчета линейной интерполяции
    CREATE OR REPLACE FUNCTION calculate_interpolation(
        p_x numeric,
        p_params interpolation_params
    )
    RETURNS numeric
    LANGUAGE plpgsql
    AS $func$
    DECLARE
        v_dx numeric;
        v_dy numeric;
    BEGIN
        v_dx := p_params.x1 - p_params.x0;
        v_dy := p_params.y1 - p_params.y0;

        IF v_dx = 0 OR v_dy = 0 OR v_dx IS NULL THEN
            RETURN COALESCE(p_params.y0, p_params.y1);
        END IF;

        RETURN ROUND(
            p_params.y0 + ((p_x - p_params.x0) * v_dy) / v_dx,
            1
        );
    END;
    $func$;

    COMMIT;

    -- Комментарии
    COMMENT ON TYPE interpolation_params IS 'Параметры для линейной интерполяции (x0, y0, x1, y1)';
    COMMENT ON FUNCTION get_interpolation_params(numeric) IS 'Определение параметров для интерполяции по температуре';
    COMMENT ON FUNCTION calculate_interpolation(numeric, interpolation_params) IS 'Расчет значения линейной интерполяции';

    COMMIT;
END $$;