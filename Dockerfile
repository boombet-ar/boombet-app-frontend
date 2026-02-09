# ---------- STAGE 1: Build Flutter Web ----------
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

ARG API_HOST
ARG API_SCHEME
ARG API_PORT
ARG USERDATA_KEY
ARG IMAGE_PROXY_BASE
ARG VIDEO_PROXY_BASE

RUN flutter build web --dart-define=API_HOST=${API_HOST} --dart-define=API_SCHEME=${API_SCHEME} --dart-define=API_PORT=${API_PORT} --dart-define=USERDATA_KEY=${USERDATA_KEY} --dart-define=IMAGE_PROXY_BASE=${IMAGE_PROXY_BASE} --dart-define=VIDEO_PROXY_BASE=${VIDEO_PROXY_BASE}

# ---------- STAGE 2: Nginx ----------
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
