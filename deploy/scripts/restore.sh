#!/usr/bin/env bash
# Eski serverdan ko'chirish / zaxiradan tiklash.
#   ./deploy/scripts/restore.sh <db.sql.gz> [uploads.tgz]
# DIQQAT: bazadagi joriy ma'lumotlar dump bilan almashtiriladi.
set -euo pipefail
cd "$(dirname "$0")/../.."
DB="${1:?db.sql.gz yo'lini bering}"; UP="${2:-}"

docker compose up -d mysql redis
echo "MySQL tayyor bo'lishini kutyapmiz..."
until [ "$(docker inspect -f '{{.State.Health.Status}}' "$(docker compose ps -q mysql)")" = "healthy" ]; do sleep 3; done

echo "Baza tiklanmoqda: $DB"
gunzip -c "$DB" | docker compose exec -T mysql sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot "$MYSQL_DATABASE"'

if [ -n "$UP" ]; then
  echo "Rasmlar tiklanmoqda: $UP"
  docker compose run --rm --no-deps -T --entrypoint sh -u root backend \
    -c 'tar xzf - -C /app && chown -R node:node /app/public' < "$UP"
fi

docker compose up -d --build
docker compose ps
