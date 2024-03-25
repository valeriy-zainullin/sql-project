#!/bin/bash

set -e

run_psql() {
    psql -U valeriy dbproject -f $1
}

declare -a files=(
  0-drop-tables.sql
  1-create-tables.sql
  2-do-inserts.psql
  3-do-requests.sql
)

for file in "${files[@]}"; do
  run_psql "$file"
done
