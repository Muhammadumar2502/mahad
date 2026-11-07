#!/usr/bin/env bash
# Baza + yuklangan rasmlar zaxirasi: ./deploy/scripts/backup.sh  ->  backups/<sana>/
set -euo pipefail
cd "$(dirname "$0")/../.."
set -a; . ./.env; set +a
TS=$(date +%Y%m%d_%H%M)
OUT="backups/$TS"; mkdir -p "$OUT"

docker compose exec -T mysql sh -c \
  'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysqldump -uroot --single-transaction --routines --triggers --no-tablespaces "$MYSQL_DATABASE"' \
  | gzip > "$OUT/db.sql.gz"

docker compose exec -T backend tar czf - -C /app public > "$OUT/uploads.tgz"

ls -lh "$OUT"
# 14 kundan eski zaxiralarni o'chirish
find backups -maxdepth 1 -type d -name '20*' -mtime +14 -exec rm -rf {} + 2>/dev/null || true
