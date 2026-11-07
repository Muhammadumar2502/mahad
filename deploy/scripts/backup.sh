#!/usr/bin/env bash
# Darhol zaxira (backup konteyneri orqali) -> backups/<sana>/db.sql.gz + uploads.tgz
set -euo pipefail
cd "$(dirname "$0")/../.."
docker compose run --rm backup now
