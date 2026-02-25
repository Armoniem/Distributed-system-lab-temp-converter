# ─── Stage 1: Build Flutter web ───────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy pubspec files first for layer caching
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy remaining source
COPY . .

# Build for web with the backend URL injected at build time
ARG BACKEND_URL=http://backend-service:8080
RUN flutter build web \
    --release \
    --dart-define=BACKEND_URL=${BACKEND_URL} \
    --no-tree-shake-icons

# ─── Stage 2: Nginx to serve static files ────────────────────────────────────
FROM nginx:1.25-alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

COPY --from=builder /app/build/web /usr/share/nginx/html

# Custom nginx config for Flutter web (SPA routing)
COPY nginx.conf /etc/nginx/conf.d/tempconv.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
