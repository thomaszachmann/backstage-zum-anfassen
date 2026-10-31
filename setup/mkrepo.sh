#!/usr/bin/env bash
# mkrepo.sh <org/repo> <verzeichnis> – legt ein Repo in Forgejo an (vorhandenes wird
# gelöscht), pusht den Inhalt des Verzeichnisses nach main, Bot bekommt Schreibrecht.
set -euo pipefail
[ $# -eq 2 ] || { echo "Aufruf: mkrepo.sh <org/repo> <verzeichnis>" >&2; exit 2; }
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
REPO="$1"; SRC="$(cd "$2" && pwd)"; ORG="${REPO%%/*}"; NAME="${REPO#*/}"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
api "$FORGEJO/api/v1/orgs/$ORG" >/dev/null \
  || api -X POST "$FORGEJO/api/v1/orgs" -d "{\"username\":\"$ORG\"}" >/dev/null
api -X DELETE "$FORGEJO/api/v1/repos/$REPO" >/dev/null 2>&1 || true
api -X POST "$FORGEJO/api/v1/orgs/$ORG/repos" \
  -d "{\"name\":\"$NAME\",\"default_branch\":\"main\"}" >/dev/null
tmp=$(mktemp -d)
cp -R "$SRC/." "$tmp"; rm -rf "$tmp/.git"
git -C "$tmp" init -q -b main
git -C "$tmp" add -A
git -C "$tmp" -c user.name="Lab Admin" -c user.email=admin@lab.local commit -qm "Initialer Stand"
git -C "$tmp" push -q "http://$ADMIN@127.0.0.1:$FORGEJO_PORT/$REPO.git" main
rm -rf "$tmp"
api -X PUT "$FORGEJO/api/v1/repos/$REPO/collaborators/backstage-bot" \
  -d '{"permission":"write"}' >/dev/null
# Forgejo meldet ein frisch gepushtes Repo kurz als leer – warten
until api "$FORGEJO/api/v1/repos/$REPO" | jq -e '.empty == false' >/dev/null; do
  sleep 1
done
echo "✔ $REPO angelegt ($FORGEJO/$REPO)"
