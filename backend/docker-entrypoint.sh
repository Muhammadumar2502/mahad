#!/bin/sh
set -e

# Baza sxemasini Prisma schema bilan sinxronlash.
# * Bo'sh bazada — barcha jadvallarni yaratadi.
# * Mos bazada — hech narsa qilmaydi.
# * Ma'lumot yo'qolishi mumkin bo'lgan o'zgarishda — RAD ETADI (--accept-data-loss yo'q),
#   server baribir ishga tushadi, logda ogohlantirish qoladi.
if [ "${DB_SYNC:-true}" = "true" ]; then
  echo "[entrypoint] prisma db push ..."
  if ! npx prisma db push --skip-generate; then
    echo "[entrypoint] OGOHLANTIRISH: db push bajarilmadi. Sxema farqini qo'lda tekshiring."
  fi
fi

echo "[entrypoint] backend ishga tushmoqda (port ${PORT:-3333})"
exec node dist/main.js
