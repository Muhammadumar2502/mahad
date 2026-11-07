# Mahad Test Platform

Monorepo: **backend** (NestJS + Prisma + MySQL + Redis), **web** (admin panel, React + Vite), **mobile** (o'quvchilar ilovasi, Flutter).

```
.
├── backend/              NestJS API  (/api/v1)
├── web/                  Admin panel (Vite build → nginx)
├── mobile/               Flutter ilova (Android / iOS)
├── deploy/
│   ├── nginx/            nginx.conf + Dockerfile (web build + gzip + proxy)
│   ├── backup/           kunlik avtomatik zaxira skripti (konteyner ichida)
│   ├── mysql/init/       birinchi ishga tushishda yuklanadigan dump (*.sql.gz) — git'ga tushmaydi
│   └── scripts/          backup.sh, restore.sh
├── docker-compose.yml    mysql + redis + backend + nginx + backup
├── Makefile              qisqa komandalar (make up / logs / backup ...)
└── .env.example
```

## Arxitektura

```
            :80 / :2222 (web)            :3333 (eski mobil 1.3.x)
                    │                            │
                 ┌──┴────────────── nginx ───────┴──┐   gzip, rate-limit, kesh headerlari
                 │  /           → web (SPA)         │
                 │  /api/       → backend:3333      │
                 │  /static/    → uploads volume    │
                 └──────────────┬───────────────────┘
                                │
                        backend (NestJS) ── redis (kesh, login rate-limit)
                                │
                              mysql 8
```

* **Redis**: `subject/all`, `book/all`, `section/book/:id`, `student/rate`, `my-group` keshlanadi.
  Har qanday o'zgartiruvchi so'rovdan keyin tegishli kesh avtomatik tozalanadi
  (`CacheInvalidationInterceptor`). Redis ishlamasa ham backend keshsiz ishlayveradi.
* **nginx**: web statikasi oldindan gzip qilingan (`gzip_static`), API javoblari gzip,
  `/assets/*` 1 yil kesh, rasmlar to'g'ridan-to'g'ri volume'dan.
* **Hammasi Docker'da** — PM2, host'dagi Node yoki cron kerak emas. Har servis `restart: unless-stopped`
  (server qayta yoqilsa o'zi ko'tariladi), healthcheck bilan, loglar 3×10 MB bilan cheklangan.
* **backup** konteyneri har kuni `BACKUP_TIME` (UTC) da baza + rasmlarni `backups/<sana>/` ga saqlaydi,
  `BACKUP_KEEP_DAYS` kundan eskilarini o'chiradi.
* **Eski mobil ilovalar** (`http://<ip>:3333/api/v1`) o'zgarishsiz ishlaydi — 3333 port nginx orqali backendga boradi.

## Tez ishga tushirish

```bash
make env        # .env yaratadi, parollar avtomatik generatsiya qilinadi
make up         # build + ishga tushirish
make health     # {"status":"ok","db":true,"redis":true,...}
```

| Komanda | Nima qiladi |
|---|---|
| `make ps` / `make logs` | holat / backend loglari |
| `make backup` | darhol zaxira → `backups/<sana>/` |
| `make restore DB=... UPLOADS=...` | zaxiradan tiklash |
| `make update` | `git pull` + qayta build |
| `make down` | to'xtatish (ma'lumotlar volume'da saqlanadi) |

## Eski serverdan ko'chirish

1. Eski serverdan zaxira (bu repo ildizida `backups/` papkasida oxirgi nusxalar bor):
   * baza: `mahad_test_db_*.sql.gz`
   * rasmlar: `mahad_public_*.tgz`
2. Yangi serverda: Docker o'rnating, repo'ni klon qiling, `.env` ni to'ldiring.
3. Tiklash:
   ```bash
   make restore DB=backups/mahad_test_db_XXXX.sql.gz UPLOADS=backups/mahad_public_XXXX.tgz
   ```
   (Yoki dump'ni `deploy/mysql/init/` ga qo'yib `docker compose up -d` — bo'sh bazaga avtomatik yuklanadi.)
4. **Eski** serverdagi PM2 jarayonlarini to'xtating (yangi tizim PM2 ishlatmaydi): `pm2 stop Mahad-backend mahad-test-web`,
   so'ng IP/DNS ni yangi serverga yo'naltiring.
5. Zaxira avtomatik — `backup` konteyneri har kuni ishlaydi, qo'shimcha sozlash shart emas.

## Mobil ilova

```bash
cd mobile
# .env: base_url=http://<server>/api/v1  domain=http://<server>
flutter pub get
flutter build apk --release
```

* Versiya: `1.4.0+140` (telefonlardagi oxirgi eski versiya — 1.3.8).
* Release imzo: `android/key.properties` + `android/app/app.jks` (git'ga tushmaydi). Ular bo'lmasa build debug kalit bilan yig'iladi —
  bunday APK eski o'rnatilgan ilova ustidan yangilanmaydi.
* Minimal talab qilinadigan versiya backend `.env` dagi `APP_VERSION` orqali boshqariladi.

## Backend — lokal ishlab chiqish

```bash
cd backend
cp .env.example .env
npm install
npm run start:dev
```

Sxema: `prisma/schema.prisma`. Konteyner har ishga tushganda `prisma db push` ni xavfsiz rejimda bajaradi
(ma'lumot yo'qotadigan o'zgarishni rad etadi).
