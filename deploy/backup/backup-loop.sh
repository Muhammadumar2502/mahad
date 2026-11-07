#!/bin/sh
# Docker ichidagi avtomatik zaxira: har kuni BACKUP_TIME (UTC, HH:MM) da
#   /backups/<sana>/db.sql.gz + uploads.tgz
# BACKUP_KEEP_DAYS kundan eski zaxiralar o'chiriladi.
set -eu

BACKUP_TIME="${BACKUP_TIME:-22:00}"     # 22:00 UTC = 03:00 Toshkent
KEEP="${BACKUP_KEEP_DAYS:-14}"

run_backup() {
  ts=$(date -u +%Y%m%d_%H%M)
  dir="/backups/$ts"
  mkdir -p "$dir"
  echo "[backup] $ts boshlandi"
  if MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysqldump -h mysql -uroot \
       --single-transaction --routines --triggers --no-tablespaces \
       "$MYSQL_DATABASE" | gzip > "$dir/db.sql.gz.tmp"; then
    mv "$dir/db.sql.gz.tmp" "$dir/db.sql.gz"
  else
    echo "[backup] XATO: mysqldump bajarilmadi"; rm -rf "$dir"; return 1
  fi
  # Eski server arxivi bilan bir xil tuzilma: public/books, public/sections, ...
  tar czf "$dir/uploads.tgz" -C /data public 2>/dev/null || echo "[backup] ogohlantirish: rasmlar arxivlanmadi"
  ls -lh "$dir"
  find /backups -mindepth 1 -maxdepth 1 -type d -name '20*' -mtime +"$KEEP" -exec rm -rf {} + 2>/dev/null || true
  echo "[backup] tayyor: $dir"
}

# `docker compose run --rm backup now` — darhol bitta zaxira
if [ "${1:-}" = "now" ]; then
  run_backup
  exit $?
fi

echo "[backup] har kuni $BACKUP_TIME UTC da, $KEEP kun saqlanadi"
while true; do
  now=$(date -u +%s)
  target=$(date -u -d "$(date -u +%Y-%m-%d) $BACKUP_TIME" +%s 2>/dev/null || echo 0)
  [ "$target" -le "$now" ] && target=$((target + 86400))
  sleep $((target - now))
  run_backup || true
  sleep 60
done
