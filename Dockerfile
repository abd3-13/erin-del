# 1 - Build Caddy modules
FROM --platform=$BUILDPLATFORM caddy:2.9.1-builder AS builder

ARG TARGETARCH
RUN GOARCH=$TARGETARCH xcaddy build \
    --with github.com/caddyserver/replace-response

# 2 - Build the Go backend that handles video deletion
FROM --platform=$BUILDPLATFORM golang:alpine AS gobuild

ARG TARGETARCH

WORKDIR /app

COPY erin-del.go ./

RUN GOOS=linux GOARCH=$TARGETARCH go build -o erin-del-vid erin-del.go

# 3 - Build the React frontend
FROM node:20-alpine AS erinbuild

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@9.15.9 --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY ./public ./public
COPY ./src ./src

RUN pnpm build

# 4 - Runtime: Caddy + Go backend + built frontend
FROM caddy:2.9.1-alpine

# Add curl for the entrypoint health checks
RUN apk add --no-cache curl

# Install the modules
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY --from=gobuild /app/erin-del-vid /usr/bin/

# Set Caddy configuration
COPY docker/Caddyfile /etc/caddy/
COPY docker/entrypoint.sh /

# Install the React App
COPY --from=erinbuild /app/build /srv

# Set default environment variables
ENV AUTH_ENABLED="true"
ENV AUTH_SECRET="\$2a\$14\$qRW8no8UDmSwIWM6KHwdRe1j/LMrxoP4NSM756RVodqeUq5HzG6t."
ENV PUBLIC_URL="https://localhost"
ENV APP_TITLE="Erin - TikTok feed for your own media"
ENV AUTOPLAY_ENABLED="false"
ENV IMAGE_DISPLAY_DURATION="5"
ENV START_MUTED="true"
ENV PROGRESS_BAR_POSITION="bottom"
ENV IGNORE_HIDDEN_PATHS="false"
ENV SCROLL_DIRECTION="vertical"
ENV USE_CUSTOM_SKIN="false"
ENV VIDEO_START_POSITION="start"

# Fork-specific defaults (delete API + dual-process entrypoint)
ENV DELAPI_URL="http://localhost:5000"
ENV CORS_ORIGIN="*"
ENV WEB_PORT="80"
ENV GO_PORT="5000"

# Entrypoint shell script will run both processes
ENTRYPOINT ["sh", "/entrypoint.sh"]
