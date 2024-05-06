#!/bin/bash

set -e

run_psql() {
  set -x
  psql -P pager=off -U valeriy dbproject -f "$1"
  { set +x; } 2>/dev/null
}

declare -a files=(
  0-drop-tables.sql
  1-create-tables.sql
  2-do-inserts.psql
  3-do-requests.sql
  4-create-views.sql
  5-create-indices.sql
  6-create-procedures.sql
)

pushd scripts
for file in "${files[@]}"; do
  run_psql "$file"
done
popd

echo "Activating venv.."
python3 -m venv .venv
source .venv/bin/activate
echo "Activated venv."

set -x
pip install -r tests/requirements.txt
pytest -v tests/all.py
