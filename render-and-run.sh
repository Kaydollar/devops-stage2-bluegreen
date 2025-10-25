#!/bin/sh
set -eu

# load .env (simple parser)
if [ ! -f .env ]; then
  echo ".env file missing. Copy .env.example to .env and edit if needed."
  exit 1
fi
export $(grep -v '^#' .env | sed -E 's/ *= */=/g' | xargs)

# Set UPSTREAM_SERVERS depending on ACTIVE_POOL
if [ "$ACTIVE_POOL" = "blue" ]; then
  export UPSTREAM_SERVERS="server localhost:${BLUE_PORT} max_fails=1 fail_timeout=2s; server localhost:${GREEN_PORT} backup;"
else
  export UPSTREAM_SERVERS="server localhost:${GREEN_PORT} max_fails=1 fail_timeout=2s; server localhost:${BLUE_PORT} backup;"
fi

# Render nginx config
envsubst '$UPSTREAM_SERVERS' < nginx/nginx.conf.template > nginx/generated.conf

# Start docker compose (no build step needed)
docker compose up -d
echo "Services starting... wait a few seconds then test http://localhost:${NGINX_PUBLIC_PORT}/version"

