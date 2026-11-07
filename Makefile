# Mahad — qisqa komandalar.  `make` yoki `make help`
.DEFAULT_GOAL := help
DC := docker compose

help: ## Komandalar ro'yxati
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[32m%-10s\033[0m %s\n", $$1, $$2}'

env: ## .env yaratish (parollar avtomatik generatsiya qilinadi)
	@test -f .env && echo ".env allaqachon bor" || ( \
	  sed -e "s/change_root_password/$$(openssl rand -hex 16)/" \
	      -e "s/change_app_password/$$(openssl rand -hex 16)/" \
	      -e "s/^JWT_SECRET=change_me/JWT_SECRET=$$(openssl rand -hex 32)/" .env.example > .env && \
	  chmod 600 .env && echo ".env yaratildi" )

up: ## Build qilib ishga tushirish
	$(DC) up -d --build
	@$(DC) ps

down: ## To'xtatish (ma'lumotlar saqlanadi)
	$(DC) down

restart: ## Backend va nginx ni qayta ishga tushirish
	$(DC) restart backend nginx

ps: ## Holat
	$(DC) ps

logs: ## Backend loglari (Ctrl+C — chiqish)
	$(DC) logs -f --tail=200 backend

health: ## API holati
	@curl -fsS http://localhost:$${HTTP_PORT:-80}/api/v1/health && echo

backup: ## Darhol zaxira -> backups/<sana>/
	$(DC) run --rm backup now

restore: ## Tiklash: make restore DB=backups/x/db.sql.gz UPLOADS=backups/x/uploads.tgz
	./deploy/scripts/restore.sh $(DB) $(UPLOADS)

update: ## git pull + qayta build
	git pull --ff-only && $(DC) up -d --build && $(DC) image prune -f

.PHONY: help env up down restart ps logs health backup restore update
