# Создание баз данных

Пока подготовлены только файлы создания двух баз:

- `restore_demo.sh` — восстанавливает `demo` из `database.sql.gz`, расположенного рядом со скриптом.
- `create_simple.sql` — создает `simple` со схемой `details` и данными из задания.

Оба скрипта при запуске удаляют существующую одноименную базу и создают ее заново. Подготовка файлов сама по себе базы не изменяет.

## Запуск

Команды выполняются из директории `MAI_DatabaseDesing`:

```bash
bash database_create/restore_demo.sh
sudo -u postgres psql -X -d postgres -v ON_ERROR_STOP=1 -f database_create/create_simple.sql
```

Для восстановления нужны PostgreSQL 17 или новее, доступные расширения `btree_gist`, `cube`, `earthdistance` и локаль `en_US.UTF-8`, указанная в дампе. PostgreSQL должен быть запущен. Скрипты используют локальное подключение от пользователя `postgres` через `sudo`; пароль `sudo`, если он запрошен, вводится в терминале.

Перед пересозданием закройте другие подключения к `demo` и `simple`: PostgreSQL не удалит базу с активными подключениями. Принудительное завершение чужих соединений скрипты не выполняют.

`restore_demo.sh` проверяет целостность архива, распаковывает его потоком и передает SQL в `psql`. Единственная поправка к содержимому дампа — `DROP DATABASE demo` заменяется на `DROP DATABASE IF EXISTS demo`, чтобы первое восстановление работало и при отсутствии базы. Исходный архив не изменяется.

В `create_simple.sql` создание и заполнение таблиц выполняются в одной транзакции. Данные сохранены по заданию, включая два одинаковых вхождения поставки `('s1', 'p1', 'j1', 200)`. Удалять пустые таблицы после пересоздания всей базы не требуется, поэтому команды `DROP TABLE` из исходного примера опущены.

## Проверка

После каждого запуска код завершения должен быть `0`:

```bash
echo $?
```

Проверка восстановления `demo`:

```bash
sudo -u postgres psql -X -d demo -c 'SELECT bookings.version();'
sudo -u postgres psql -X -d demo -c '\dt bookings.*'
```

Проверка числа записей в `simple`:

```bash
sudo -u postgres psql -X -d simple -c 'SELECT (SELECT count(*) FROM details.s) AS suppliers, (SELECT count(*) FROM details.p) AS parts, (SELECT count(*) FROM details.j) AS projects, (SELECT count(*) FROM details.spj) AS supplies;'
```

Ожидается: **5 поставщиков, 6 деталей, 7 проектов, 25 строк поставок**.
