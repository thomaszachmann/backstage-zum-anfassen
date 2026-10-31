# env.sh – Umgebung für das Backstage-Lab. Laden mit: source ~/backstage-lab/setup/env.sh
export LAB="${LAB:-$HOME/backstage-lab}"
export PORTAL="${PORTAL:-$LAB/portal}"
# Node 24 LTS vor ein eventuell neueres System-Node stellen (Homebrew: node@24)
export PATH="${NODE_BIN:-/opt/homebrew/opt/node@24/bin}:$PATH"
export FORGEJO_NAME="${FORGEJO_NAME:-bs-forgejo}"
export FORGEJO_PORT="${FORGEJO_PORT:-3300}"
export FORGEJO="http://127.0.0.1:$FORGEJO_PORT"
export ADMIN="lab-admin:lab-admin-pw-123"                       # Lab-Wert!
export FORGEJO_TOKEN="$(cat "$LAB/setup/forgejo-token" 2>/dev/null)"
export APP_PORT="${APP_PORT:-3000}"
export BACKSTAGE_PORT="${BACKSTAGE_PORT:-7007}"
export APP="http://localhost:$APP_PORT"
export BACKSTAGE="http://localhost:$BACKSTAGE_PORT"
export BACKSTAGE_TOKEN="lab-cli-token-0123456789abcdef"         # Lab-Wert!
# bs <pfad> [curl-optionen] – Backstage-API mit dem statischen Lab-Token
bs() { local p="$1"; shift; curl -sf -H "Authorization: Bearer $BACKSTAGE_TOKEN" \
  "$@" "$BACKSTAGE/api/$p"; }
