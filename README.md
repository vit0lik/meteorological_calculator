# Метеорологический калькулятор

Расчёт метеобюллетеня «Метеосредний» по наземным измерениям (ДМК) и
по измерению сноса пуль ветровым ружьём (ВР).

## Структура

- `db/migrations` — скрипты преобразования схемы, выполняются по порядку
- `db/queries` — запросы к схеме
- `docs/artillery` — техническое задание и описание алгоритмов
- `docs/exports` — выгрузка результатов из pgAdmin
- `infra` — docker-compose и переменные окружения

## Запуск

```bash
docker compose -f infra/docker-compose.yaml up -d
```

PostgreSQL доступна на порту 15435, pgAdmin — на 5050.
Учётные данные хранятся в `infra/.env`, образец — `infra/.env.example`.

## Порядок выполнения

1. `db/migrations/001_create_schema.sql` — схема и тестовые данные
2. `db/migrations/002_normalize_parameters.sql` — перенос параметров в таблицу измерений
3. `db/queries/select_all.sql` — журнал измерений

Схема развёрнута в PostgreSQL, доступной через pgAdmin на 5050.
Синтаксис скриптов — ANSI-92.

## Документация

- [Техническое задание](docs/artillery/technical-task.md)
- [Алгоритм расчёта для ДМК](docs/artillery/algoritm-dmk.md)
- [Алгоритм расчёта для БП](docs/artillery/algoritm-bp.md)