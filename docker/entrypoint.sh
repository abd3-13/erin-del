#!/bin/sh
set -e

# Colors for terminal log formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
  echo "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
  echo "${RED}[ERROR] $1${NC}" >&2
}

# === Configurable environment defaults ===
WEB_DIR="${WEB_DIR:-./srv}"
WEB_PORT="${WEB_PORT:-8000}"
GO_PORT="${GO_PORT:-5000}"
CORS_ORIGIN="${CORS_ORIGIN:-http://127.0.0.1:$WEB_PORT}"
GO_BINARY="${GO_BINARY:-./erin-del-vid}"

# === Retry configuration ===
RETRY_COUNT="${RETRY_COUNT:-10}"
RETRY_INTERVAL="${RETRY_INTERVAL:-1}" # seconds

# === Health check function ===
health_check() {
  local name="$1"
  local url="$2"
  local retries=$RETRY_COUNT
  local delay=$RETRY_INTERVAL

  while [ $retries -gt 0 ]; do
    if curl -sSf "$url" > /dev/null; then
      log "$name is healthy at $url"
      return 0
    fi
    log "Waiting for $name at $url ($retries retries left)..."
    retries=$((retries - 1))
    sleep "$delay"
  done

  error "$name did not become healthy at $url"
  return 1
}

# === Startup checks ===
[ -x "$GO_BINARY" ] || { error "Go server binary '$GO_BINARY' not found or not executable."; exit 1; }
[ -d "$WEB_DIR" ] || { error "Web directory '$WEB_DIR' not found."; exit 1; }

# === Start  web server ===
log "Starting static web server on port $WEB_PORT (serving $WEB_DIR)"
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
WEB_PID=$!

# === Check that web server comes up ===
health_check "Web server" "http://127.0.0.1:$WEB_PORT"

# === Start Go backend server ===
log "Starting Go backend on port $GO_PORT (CORS: $CORS_ORIGIN)"
"$GO_BINARY" -port="$GO_PORT" -cors-origin="$CORS_ORIGIN" &
GO_PID=$!

# === Check Go backend health ===
health_check "Go server" "http://127.0.0.1:$GO_PORT/health"

# === Handle shutdown cleanly ===
trap 'log "Stopping..."; kill $WEB_PID $GO_PID; wait $WEB_PID $GO_PID; exit 0' SIGINT SIGTERM

# Wait for both services
wait $WEB_PID $GO_PID
