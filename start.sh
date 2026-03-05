#!/bin/bash
set -euo pipefail

OPENCLAW_DIR="/root/.openclaw"
CONFIG="$OPENCLAW_DIR/openclaw.json"

mkdir -p "$OPENCLAW_DIR/workspace" \
         "$OPENCLAW_DIR/agents/main/sessions" \
         "$OPENCLAW_DIR/credentials" \
         "$OPENCLAW_DIR/canvas"
chmod 700 "$OPENCLAW_DIR"

# 1) Ensure we have a gateway token
# Priority: env var -> existing config -> generate new
if [ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  if [ -f "$CONFIG" ] && command -v jq >/dev/null 2>&1; then
    TOKEN_IN_CONFIG="$(jq -r '.gateway.auth.token // empty' "$CONFIG" 2>/dev/null || true)"
    if [ -n "$TOKEN_IN_CONFIG" ]; then
      export OPENCLAW_GATEWAY_TOKEN="$TOKEN_IN_CONFIG"
    fi
  fi
fi

if [ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  export OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 32)"
  echo "Generated OPENCLAW_GATEWAY_TOKEN: $OPENCLAW_GATEWAY_TOKEN"
  echo "(Save this token for remote gateway access)"
fi

# 2) Only create a base config if one doesn't already exist
# (Important: preserves WhatsApp config you set via `openclaw configure`)
if [ ! -f "$CONFIG" ]; then
  echo "No existing config found; creating base config at $CONFIG"

  cat > "$CONFIG" <<EOF
{
  "agents": {
    "defaults": {
      "workspace": "~/.openclaw/workspace",
      "model": {
        "primary": "anthropic/claude-sonnet-4-20250514"
      }
    }
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "token": "$OPENCLAW_GATEWAY_TOKEN"
    }
  },
  "channels": {}
}
EOF
else
  echo "Existing config found; leaving it as-is (preserving WhatsApp/channel settings)."
  # Ensure config contains a token (if not, inject it)
  if command -v jq >/dev/null 2>&1; then
    HAS_TOKEN="$(jq -r '.gateway.auth.token // empty' "$CONFIG" 2>/dev/null || true)"
    if [ -z "$HAS_TOKEN" ]; then
      echo "Config missing gateway.auth.token; injecting token."
      tmp="$(mktemp)"
      jq --arg tok "$OPENCLAW_GATEWAY_TOKEN" '
        .gateway.auth.token = ($tok)
      ' "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi
  fi
fi

chmod 600 "$CONFIG"

# 3) Optional: run doctor (but don't crash the container if it fails)
echo "Running openclaw doctor --fix..."
openclaw doctor --fix || true

# 4) Start gateway as the FOREGROUND process (keeps the service running)
PORT="${PORT:-18789}"
echo "Starting OpenClaw gateway on port ${PORT}..."

# IMPORTANT: do NOT pass --bind 0.0.0.0 (your OpenClaw build rejects it).
# Staying on loopback is fine for WhatsApp since it runs inside the container.
exec openclaw gateway --port "$PORT"