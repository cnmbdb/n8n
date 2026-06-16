#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

seed_dir="n8n-seed"
runtime_dir="n8n-data"
timestamp="$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$seed_dir/database.sqlite" ] || [ ! -f "$seed_dir/config" ]; then
  echo "Missing n8n seed files under $seed_dir" >&2
  exit 1
fi

docker compose down

mkdir -p "$runtime_dir/nodes" articles lmg horizon

restore_db="${FORCE_RESTORE_N8N_DB:-0}"

if [ ! -f "$runtime_dir/database.sqlite" ]; then
  restore_db=1
elif command -v sqlite3 >/dev/null 2>&1; then
  integrity="$(sqlite3 "$runtime_dir/database.sqlite" 'PRAGMA integrity_check;' 2>/dev/null || true)"
  workflow_count="$(sqlite3 "$runtime_dir/database.sqlite" 'select count(*) from workflow_entity;' 2>/dev/null || echo 0)"
  if [ "$integrity" != "ok" ] || [ "${workflow_count:-0}" = "0" ]; then
    restore_db=1
  fi
fi

if [ "$restore_db" = "1" ]; then
  if [ -f "$runtime_dir/database.sqlite" ]; then
    mv "$runtime_dir/database.sqlite" "$runtime_dir/database.sqlite.backup-$timestamp"
  fi
  cp "$seed_dir/database.sqlite" "$runtime_dir/database.sqlite"
fi

if [ ! -f "$runtime_dir/config" ] || [ "${FORCE_RESTORE_N8N_CONFIG:-0}" = "1" ]; then
  if [ -f "$runtime_dir/config" ]; then
    mv "$runtime_dir/config" "$runtime_dir/config.backup-$timestamp"
  fi
  cp "$seed_dir/config" "$runtime_dir/config"
fi

cp "$seed_dir/nodes/package.json" "$runtime_dir/nodes/package.json"

if [ "$(id -u)" = "0" ]; then
  chown -R 1000:1000 "$runtime_dir" articles lmg horizon
fi
chmod 700 "$runtime_dir"
chmod 700 "$runtime_dir/nodes"
chmod 600 "$runtime_dir/config"
chmod 600 "$runtime_dir/database.sqlite"

docker compose up -d --force-recreate
docker logs --tail 120 n8n
