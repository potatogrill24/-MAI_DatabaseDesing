# Создание баз данных

- `restore_demo.sh` восстанавливает `demo` из дампа «Авиаперевозки».
- `create_simple.sql` создаёт `simple` со схемой `details` и данными из задания.

Запускайте команды из корня репозитория. Для восстановления `demo` нужен PostgreSQL 17 или новее с расширениями `btree_gist`, `cube`, `earthdistance` и локалью `en_US.UTF-8`.

Положите [архив дампа](https://edu.postgrespro.ru/demo-20250901-3m.sql.gz) в `database_create/` под именем `database.sql.gz` или `demo-20250901-3m.sql.gz`. Если там есть оба файла, скрипт использует `database.sql.gz`.

**При запуске обе базы пересоздаются.** Перед этим закройте активные подключения к `demo` и `simple`.

## Запуск

### Linux

Команды рассчитаны на запущенный PostgreSQL и локальное подключение от системного пользователя `postgres` через `sudo`.

```bash
bash database_create/restore_demo.sh
sudo -u postgres psql -X -d postgres -v ON_ERROR_STOP=1 -f database_create/create_simple.sql
```

### macOS

Установите и запустите PostgreSQL 17 через [Homebrew](https://formulae.brew.sh/formula/postgresql@17). Добавьте `psql` в `PATH` текущего терминала.

```zsh
brew install postgresql@17
brew services start postgresql@17
export PATH="$(brew --prefix postgresql@17)/bin:$PATH"

psql -X -d postgres -c 'SELECT current_user, version();'
```

В том же терминале восстановите `demo` и создайте `simple` от своей учётной записи macOS.

```zsh
bash database_create/restore_demo.sh
psql -X -d postgres -v ON_ERROR_STOP=1 -f database_create/create_simple.sql
```

`restore_demo.sh` проверяет целостность архива и передаёт SQL в `psql` потоком. По пути скрипт заменяет `DROP DATABASE demo` на `DROP DATABASE IF EXISTS demo`, чтобы поддержать первый запуск.

`create_simple.sql` создаёт и заполняет таблицы в одной транзакции. Данные из задания включают две одинаковые строки поставки `('s1', 'p1', 'j1', 200)`.

## Проверка

Сразу после каждой команды запуска `echo $?` должен вывести `0`.

### Linux

```bash
sudo -u postgres psql -X -d demo -c 'SELECT bookings.version();'
sudo -u postgres psql -X -d demo -c '\dt bookings.*'
sudo -u postgres psql -X -d simple -c '
  SELECT
    (SELECT count(*) FROM details.s) AS suppliers,
    (SELECT count(*) FROM details.p) AS parts,
    (SELECT count(*) FROM details.j) AS projects,
    (SELECT count(*) FROM details.spj) AS supplies;
'
```

### macOS

```zsh
psql -X -d demo -c 'SELECT bookings.version();'
psql -X -d demo -c '\dt bookings.*'
psql -X -d simple -c '
  SELECT
    (SELECT count(*) FROM details.s) AS suppliers,
    (SELECT count(*) FROM details.p) AS parts,
    (SELECT count(*) FROM details.j) AS projects,
    (SELECT count(*) FROM details.spj) AS supplies;
'
```

Для `demo` команды выводят версию набора данных и список таблиц схемы `bookings`. Для `simple` ожидаются **5 поставщиков, 6 деталей, 7 проектов и 25 строк поставок**.
