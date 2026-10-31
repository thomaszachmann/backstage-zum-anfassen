#!/usr/bin/env bash
# check.sh – prüft das Trainingsgelände (✔/✘). Exit-Code = Anzahl Fehler.
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"; else echo "✘ $1"; fail=$((fail+1)); fi; }

t "Docker läuft" "docker info"
t "Node 24 (node -v)" "node -v | grep -q '^v24\.'"
t "Yarn 4 über Corepack (im Portal)" "cd '$PORTAL' && yarn --version | grep -q '^4\.'"
t "Forgejo erreichbar unter $FORGEJO" "curl -sf $FORGEJO/api/healthz"
t "Bot-Token gültig (backstage-bot)" \
  "curl -sf -H \"Authorization: token \$FORGEJO_TOKEN\" $FORGEJO/api/v1/user \
     | jq -e '.login == \"backstage-bot\"'"
t "Repo kranich/sendungs-api vorhanden (sonst: seed.sh)" \
  "curl -sf -u \$ADMIN $FORGEJO/api/v1/repos/kranich/sendungs-api"
t "Backend bereit ($BACKSTAGE)" "curl -sf $BACKSTAGE/.backstage/health/v1/readiness"
t "Frontend erreichbar ($APP)" "curl -sf $APP"
t "Katalog-API mit Lab-Token" "bs catalog/entities?limit=1"
exit "$fail"
