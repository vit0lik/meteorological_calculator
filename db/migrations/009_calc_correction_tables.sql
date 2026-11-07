DO $$
BEGIN
    -- 1: Зачистка старых структур
    BEGIN
        DROP TABLE IF EXISTS temp_deviation CASCADE;
        DROP TABLE IF EXISTS wind_corrections CASCADE;
        DROP SEQUENCE IF EXISTS temp_deviation_seq CASCADE;
        DROP SEQUENCE IF EXISTS wind_corrections_seq CASCADE;

        DROP TABLE IF EXISTS calc_correction CASCADE;
        DROP TABLE IF EXISTS calc_correction_types CASCADE;
        DROP TABLE IF EXISTS calc_correction_headers CASCADE;
        DROP TABLE IF EXISTS calc_correction_heights CASCADE;
        
        DROP SEQUENCE IF EXISTS calc_correction_seq CASCADE;
        DROP SEQUENCE IF EXISTS calc_correction_types_seq CASCADE;
        DROP SEQUENCE IF EXISTS calc_correction_headers_seq CASCADE;
        DROP SEQUENCE IF EXISTS calc_correction_height_seq CASCADE;

        -- Исправление первой точки интерполяции
        UPDATE virtual_temperature_corrections
        SET correction = 0.0
        WHERE temp = 0.0;
    END;

    -- 2: Создание структур
    BEGIN
        CREATE SEQUENCE IF NOT EXISTS calc_correction_headers_seq START WITH 1;
        CREATE TABLE IF NOT EXISTS calc_correction_headers (
            id integer NOT NULL DEFAULT nextval('calc_correction_headers_seq') PRIMARY KEY,
            header_values integer[] NOT NULL
        );
        ALTER SEQUENCE calc_correction_headers_seq OWNED BY calc_correction_headers.id;

        CREATE SEQUENCE IF NOT EXISTS calc_correction_types_seq START WITH 1;
        CREATE TABLE IF NOT EXISTS calc_correction_types (
            id integer NOT NULL PRIMARY KEY DEFAULT nextval('calc_correction_types_seq'),
            parent_id integer REFERENCES calc_correction_types(id) ON DELETE CASCADE,
            equipment_id integer REFERENCES equipment_types(id) ON DELETE CASCADE,
            header_id integer REFERENCES calc_correction_headers(id) ON DELETE RESTRICT,
            description varchar(255) NOT NULL
        );
        ALTER SEQUENCE calc_correction_types_seq OWNED BY calc_correction_types.id;

        CREATE SEQUENCE IF NOT EXISTS calc_correction_seq START WITH 1;
        CREATE TABLE IF NOT EXISTS calc_correction (
            id integer NOT NULL PRIMARY KEY DEFAULT nextval('calc_correction_seq'),
            height_id integer NOT NULL REFERENCES standard_heights(id) ON DELETE CASCADE,
            type_id integer NOT NULL REFERENCES calc_correction_types(id) ON DELETE CASCADE,
            row_values integer[] NOT NULL,
            UNIQUE (height_id, type_id)
        );
        ALTER SEQUENCE calc_correction_seq OWNED BY calc_correction.id;

        -- Комментарии к таблицам и колонкам
        COMMENT ON TABLE calc_correction_headers IS 'Заголовки таблиц корректировок';
        COMMENT ON COLUMN calc_correction_headers.id IS 'Уникальный код заголовка';
        COMMENT ON COLUMN calc_correction_headers.header_values IS 'Значения в заголовке таблицы';

        COMMENT ON TABLE calc_correction_types IS 'Справочник типов таблиц корректировок';
        COMMENT ON COLUMN calc_correction_types.id IS 'Уникальный код типа';
        COMMENT ON COLUMN calc_correction_types.parent_id IS 'Уникальный код владельца - тип таблицы';
        COMMENT ON COLUMN calc_correction_types.equipment_id IS 'Тип оборудования';
        COMMENT ON COLUMN calc_correction_types.header_id IS 'Ссылка на заголовок таблицы';
        COMMENT ON COLUMN calc_correction_types.description IS 'Описание к таблице';

        COMMENT ON TABLE calc_correction IS 'Универсальная таблица значений корректировок';
        COMMENT ON COLUMN calc_correction.id IS 'Уникальный код записи';
        COMMENT ON COLUMN calc_correction.height_id IS 'Код высоты';
        COMMENT ON COLUMN calc_correction.type_id IS 'Код типа таблиц';
        COMMENT ON COLUMN calc_correction.row_values IS 'Значения с корректировками';
    END;

    -- 3: Заполнение заголовков и типов корректировок
    BEGIN
        INSERT INTO calc_correction_headers (id, header_values) VALUES
            (1, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),
            (2, ARRAY[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),
            (3, ARRAY[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);

        INSERT INTO calc_correction_types (id, parent_id, equipment_id, header_id, description) VALUES
            (1, NULL, NULL, 1, 'Таблица 2'),
            (2, NULL, NULL, NULL, 'Таблица 3, скорость среднего ветра'),
            (3, NULL, NULL, NULL, 'Таблица 3, направление среднего ветра'),
            (4, 2, 2, 2, 'Таблица 3, Скорость среднего ветра (ВР)'),
            (5, 3, 2, 2, 'Таблица 3, Направление среднего ветра (ВР)'),
            (6, 2, 1, 3, 'Таблица 3, Скорость среднего ветра (ДМК)'),
            (7, 3, 1, 3, 'Таблица 3, Направление среднего ветра (ДМК)'),
            (8, 1, NULL, 1, 'Таблица 2, Положительные температуры'),
            (9, 1, NULL, 1, 'Таблица 2, Отрицательные температуры');
            
        -- Синхронизация последовательностей после явной вставки ID
        PERFORM setval('calc_correction_headers_seq', (SELECT coalesce(max(id), 1) FROM calc_correction_headers));
        PERFORM setval('calc_correction_types_seq', (SELECT coalesce(max(id), 1) FROM calc_correction_types));
    END;

    -- 4: Матричное заполнение данных Таблиц 2 и 3
    BEGIN
        -- Тип 9: Таблица 2, отрицательные значения
        INSERT INTO calc_correction (height_id, type_id, row_values)
        SELECT id, 9, CASE id
            WHEN 1 THEN ARRAY[-1,-2,-3,-4,-5,-6,-7,-8,-8,-9,-20,-29,-39,-49]
            WHEN 2 THEN ARRAY[-1,-2,-3,-4,-5,-6,-6,-7,-8,-9,-19,-29,-38,-48]
            WHEN 3 THEN ARRAY[-1,-2,-3,-4,-5,-6,-6,-7,-7,-8,-18,-28,-37,-46]
            WHEN 4 THEN ARRAY[-1,-2,-3,-4,-4,-5,-5,-6,-7,-8,-17,-26,-35,-44]
            WHEN 5 THEN ARRAY[-1,-2,-3,-3,-4,-4,-5,-6,-7,-7,-17,-25,-34,-42]
            WHEN 6 THEN ARRAY[-1,-2,-3,-3,-4,-4,-5,-6,-6,-7,-16,-24,-32,-40]
            WHEN 7 THEN ARRAY[-1,-2,-2,-3,-4,-4,-5,-5,-6,-7,-15,-23,-31,-38]
            WHEN 8 THEN ARRAY[-1,-2,-2,-3,-4,-4,-4,-5,-5,-6,-15,-22,-30,-37]
            WHEN 9 THEN ARRAY[-1,-2,-2,-3,-4,-4,-4,-4,-5,-6,-14,-20,-27,-34]
        END FROM standard_heights;

        -- Тип 8: Таблица 2, положительные значения
        INSERT INTO calc_correction (height_id, type_id, row_values)
        SELECT id, 8, CASE id
            WHEN 1 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
            WHEN 2 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
            WHEN 3 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
            WHEN 4 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
            WHEN 5 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
            WHEN 6 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
            WHEN 7 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
            WHEN 8 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
            WHEN 9 THEN ARRAY[1,2,3,4,5,6,7,8,9,10,20,30,0,0]
        END FROM standard_heights;

        -- Тип 4: Таблица 3, Скорость ветра (ВР)
        INSERT INTO calc_correction (height_id, type_id, row_values)
        SELECT id, 4, CASE id
            WHEN 1 THEN ARRAY[3,4,5,6,7,7,8,9,10,11,12,12]
            WHEN 2 THEN ARRAY[4,5,6,7,8,9,10,11,12,13,14,15]
            WHEN 3 THEN ARRAY[4,5,6,7,8,9,10,11,13,14,15,16]
            WHEN 4 THEN ARRAY[4,5,7,8,8,9,11,12,13,15,15,16]
            WHEN 5 THEN ARRAY[4,6,7,8,9,10,11,13,14,15,17,17]
            WHEN 6 THEN ARRAY[4,6,7,8,9,10,11,13,14,16,17,18]
            WHEN 7 THEN ARRAY[4,6,8,9,9,10,12,14,15,16,18,19]
            WHEN 8 THEN ARRAY[5,6,8,9,10,11,12,14,15,17,18,19]
            WHEN 9 THEN ARRAY[5,6,8,9,10,11,12,14,16,18,19,20]
        END FROM standard_heights;

        -- Тип 5: Таблица 3, Направление ветра (ВР)
        INSERT INTO calc_correction (height_id, type_id, row_values)
        SELECT id, 5, CASE id
            WHEN 1 THEN ARRAY[0] WHEN 2 THEN ARRAY[1] WHEN 3 THEN ARRAY[2]
            WHEN 4 THEN ARRAY[2] WHEN 5 THEN ARRAY[3] WHEN 6 THEN ARRAY[3]
            WHEN 7 THEN ARRAY[3] WHEN 8 THEN ARRAY[4] WHEN 9 THEN ARRAY[4]
        END FROM standard_heights;

        -- Тип 6: Таблица 3, Скорость ветра (ДМК)
        INSERT INTO calc_correction (height_id, type_id, row_values)
        SELECT id, 6, CASE id
            WHEN 1 THEN ARRAY[4,6,8,9,10,12,14,15,16,18,20,21,22]
            WHEN 2 THEN ARRAY[5,7,10,11,12,14,17,18,20,22,23,25,27]
            WHEN 3 THEN ARRAY[5,8,10,11,13,15,18,19,21,23,25,27,28]
            WHEN 4 THEN ARRAY[5,8,11,12,13,16,19,20,22,24,26,28,30]
            WHEN 5 THEN ARRAY[6,8,11,13,14,17,20,21,23,25,27,29,32]
            WHEN 6 THEN ARRAY[6,9,11,13,14,17,20,21,24,26,28,30,32]
            WHEN 7 THEN ARRAY[6,9,12,14,15,18,21,22,25,27,29,32,34]
            WHEN 8 THEN ARRAY[6,9,12,14,15,18,21,23,25,28,30,32,36]
            WHEN 9 THEN ARRAY[6,10,12,14,16,19,22,24,26,29,32,34,36]
        END FROM standard_heights;

        -- Тип 7: Таблица 3, Направление ветра (ДМК)
        INSERT INTO calc_correction (height_id, type_id, row_values)
        SELECT id, 7, CASE id
            WHEN 1 THEN ARRAY[1] WHEN 2 THEN ARRAY[2] WHEN 3 THEN ARRAY[3]
            WHEN 4 THEN ARRAY[3] WHEN 5 THEN ARRAY[4] WHEN 6 THEN ARRAY[4]
            WHEN 7 THEN ARRAY[4] WHEN 8 THEN ARRAY[5] WHEN 9 THEN ARRAY[5]
        END FROM standard_heights;
    END;
END $$;