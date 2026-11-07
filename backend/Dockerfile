# ---------- 1) bog'liqliklar + build ----------
FROM node:22-bookworm-slim AS build
WORKDIR /app
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
COPY prisma ./prisma
RUN npm ci --no-audit --no-fund

COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN npm run build \
 && npm prune --omit=dev --no-audit --no-fund \
 && npx prisma generate

# ---------- 2) runtime ----------
FROM node:22-bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssl ca-certificates tini \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV NODE_ENV=production \
    PORT=3333

COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --from=build --chown=node:node /app/prisma ./prisma
COPY --chown=node:node package.json docker-entrypoint.sh ./

RUN chmod +x docker-entrypoint.sh \
 && mkdir -p public/books public/sections public/subjects \
 && chown -R node:node public

USER node
EXPOSE 3333

HEALTHCHECK --interval=15s --timeout=5s --start-period=40s --retries=5 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3333)+'/api/v1/health').then(r=>r.json()).then(j=>process.exit(j.db?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["/usr/bin/tini", "--", "./docker-entrypoint.sh"]
