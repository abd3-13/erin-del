# 1- Build Caddy modules
FROM caddy:2.8.4-builder AS builder

RUN xcaddy build \
    --with github.com/caddyserver/replace-response

# 2 - Buidl Go backend for the delete
FROM golang:alpine AS gobuild

WORKDIR /app

COPY erin-del.go ./

RUN go build -o erin-del-vid

# 3 - Set up Caddy and the frontend built beforehand
FROM caddy:2.8.4-alpine

# Install the modules
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY --from=gobuild /app/erin-del-vid ./

# Set Caddy configuration
COPY docker/Caddyfile /etc/caddy/
COPY docker/entrypoint.sh ./

# Install the React App
COPY ./build /srv

# Set default environment variables
ENV AUTH_ENABLED "false"
ENV AUTH_SECRET "\$2a\$14\$qRW8no8UDmSwIWM6KHwdRe1j/LMrxoP4NSM756RVodqeUq5HzG6t."
ENV PUBLIC_URL "https://localhost"
ENV APP_TITLE "Erin - TikTok feed for your own clips"
ENV AUTOPLAY_ENABLED "false"
ENV PROGRESS_BAR_POSITION "bottom"
ENV IGNORE_HIDDEN_PATHS "false"
ENV SCROLL_DIRECTION "vertical"
ENV USE_CUSTOM_SKIN "false"
ENV DELAPI_URL = "http://localhost"

# Entrypoint shell script will run both
ENTRYPOINT ["sh", "entrypoint.sh"]
