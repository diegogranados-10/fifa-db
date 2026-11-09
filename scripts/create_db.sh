#!/usr/bin/env bash
# Creates an empty database from schema.sql.
# Usage: scripts/create_db.sh [output_path]   (default: fifa.sqlite3)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$root/fifa.sqlite3}"

if [ -e "$out" ]; then
  echo "Refusing to overwrite existing file: $out" >&2
  echo "Delete it first or pass another path." >&2
  exit 1
fi

sqlite3 "$out" < "$root/schema.sql"
echo "Created $out with $(sqlite3 "$out" "select count(*) from sqlite_master where type='table' and name not like 'sqlite_%'") tables."
