#!/usr/bin/env bash

set -euo pipefail

# Дамп расположен в той же директории, что и этот скрипт.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dump_file="$script_dir/database.sql.gz"

if [[ ! -f "$dump_file" ]]; then
	dump_file="$script_dir/demo-20250901-3m.sql.gz"
fi

if [[ ! -f "$dump_file" ]]; then
	printf 'Не найден database.sql.gz или demo-20250901-3m.sql.gz в %s\n' "$script_dir" >&2
	exit 1
fi

psql_command=(sudo -u postgres psql)
if [[ "$(uname -s)" == Darwin ]]; then
	psql_command=(psql)
fi

# Проверяем архив до выполнения содержащихся в нем SQL-команд.
gzip -t -- "$dump_file"

# Дамп сам удаляет и создает demo. IF EXISTS позволяет запустить его впервые.
# Подключаемся к служебной базе postgres, поскольку demo будет пересоздана.
gzip -dc -- "$dump_file" \
	| sed 's/^DROP DATABASE demo;$/DROP DATABASE IF EXISTS demo;/' \
	| "${psql_command[@]}" -X --dbname=postgres --set=ON_ERROR_STOP=1
