# Build konteksti: repo ildizi (docker-compose.yml dagi context: .)

# ---------- 1) web panelni build qilish ----------
FROM node:22-alpine AS web
WORKDIR /web
COPY web/package.json web/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY web/ ./
# Bitta domenda ishlaydi: API va rasmlar nisbiy yo'l bilan.
ENV VITE_BASE_URL=/api/v1 \
    VITE_STATIC_PATH=
RUN npm run build \
 && find dist -type f \( -name '*.js' -o -name '*.css' -o -name '*.html' -o -name '*.svg' -o -name '*.json' \) \
      -size +1k -exec gzip -9 -k {} \;

# ---------- 2) nginx ----------
FROM nginx:1.27-alpine
RUN rm -f /etc/nginx/conf.d/default.conf
COPY deploy/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=web /web/dist /usr/share/nginx/html
EXPOSE 80 2222 3333
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1/nginx-health || exit 1
