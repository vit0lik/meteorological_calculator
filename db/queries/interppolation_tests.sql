DO $$
DECLARE
    v_res numeric;
BEGIN
    -- Пример 1 из ТЗ (t0 = 23)
    v_res := calculate_interpolation(23, get_interpolation_params(23));
    ASSERT v_res = 1.8, 'Тест 1 провален: ожидали 1.8, а получили ' || v_res;
    RAISE NOTICE 'Тест 1 пройден. Результат: %', v_res;

    -- Диапазон от 0 до 5 (t0 = 3)
    v_res := calculate_interpolation(3, get_interpolation_params(3));
    ASSERT v_res = 0.5, 'Тест 3 провален: ожидали 0.5, а получили ' || v_res;
    RAISE NOTICE 'Тест 3 пройден. Результат: %', v_res;

    -- Диапазон от 10 до 15 (t0 = 12)
    v_res := calculate_interpolation(12, get_interpolation_params(12));
    ASSERT v_res = 1.0, 'Тест 4 провален: ожидали 1.0, а получили ' || v_res;
    RAISE NOTICE 'Тест 4 пройден. Результат: %', v_res;

    -- Отрицательная температура (t0 = -5)
    v_res := calculate_interpolation(-5, get_interpolation_params(-5));
    ASSERT v_res = 0.0, 'Тест 5 провален: ожидали 0.0, а получили ' || v_res;
    RAISE NOTICE 'Тест 5 пройден. Результат: %', v_res;

END $$;