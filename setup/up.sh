#!/usr/bin/env bash
# up.sh – startet Forgejo (Lab) in Docker, legt Admin, Bot und Bot-Token an.
# Idempotent: mehrfach aufrufbar. Alle Passwörter und Tokens sind Lab-Werte!
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
IMAGE="codeberg.org/forgejo/forgejo:16.0.6-rootless"
if ! docker ps -a --format '{{.Names}}' | grep -qx "$FORGEJO_NAME"; then
  docker run -d --name "$FORGEJO_NAME" -p "127.0.0.1:$FORGEJO_PORT:3000" \
    -v "$FORGEJO_NAME-data:/var/lib/gitea" -v "$FORGEJO_NAME-conf:/etc/gitea" \
    -e FORGEJO__security__INSTALL_LOCK=true \
    -e FORGEJO__server__ROOT_URL="$FORGEJO/" \
    -e FORGEJO__database__DB_TYPE=sqlite3 \
    -e FORGEJO__service__DISABLE_REGISTRATION=true \
    -e FORGEJO__repository__DEFAULT_BRANCH=main \
    "$IMAGE" >/dev/null
fi
docker start "$FORGEJO_NAME" >/dev/null
until curl -sf "$FORGEJO/api/healthz" >/dev/null; do sleep 1; done
fj() { docker exec "$FORGEJO_NAME" forgejo admin "$@"; }
users=$(fj user list)
grep -qw lab-admin <<<"$users" || fj user create --admin --username lab-admin \
  --password lab-admin-pw-123 --email admin@lab.local --must-change-password=false
grep -qw backstage-bot <<<"$users" || fj user create --username backstage-bot \
  --password lab-bot-pw-123 --email backstage-bot@lab.local --must-change-password=false
if [ ! -s "$DIR/forgejo-token" ]; then
  fj user generate-access-token --username backstage-bot \
    --token-name "backstage-$(date +%s)" \
    --scopes write:repository,write:organization,read:user --raw > "$DIR/forgejo-token"
  chmod 600 "$DIR/forgejo-token"
fi
echo "✔ Forgejo läuft: $FORGEJO (lab-admin / lab-admin-pw-123)"
