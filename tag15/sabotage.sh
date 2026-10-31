#!/usr/bin/env bash
# sabotage.sh – Tag 15: baut einen Fehler ins Lab ein (und wieder aus).
#   sabotage.sh <1-8>           Szenario n auslösen
#   sabotage.sh <1-8> --reset   Szenario n zurücksetzen
#   sabotage.sh random          zufälliges Szenario auslösen (Nummer bleibt geheim)
#   sabotage.sh status          aktive Szenarien zeigen (Spoiler!)
#   sabotage.sh reset-all       alle aktiven Szenarien zurücksetzen
# Nur für das Lab gedacht. Alle Zugangsdaten sind Lab-Werte!
set -euo pipefail
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
PG="${PG:-bs-postgres}"                          # Postgres-Container aus Tag 13
STATE="$LAB/tag15/.sabotage"; mkdir -p "$STATE"
BOT="backstage-bot:lab-bot-pw-123"               # Lab-Wert!
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
log() { echo "• $*"; }
restart() { log "Portal wird neu gestartet …"
  "$LAB/setup/portal.sh" restart >/dev/null || true; }

# Datei in einem Forgejo-Repo ersetzen (Contents-API, Commit auf main)
put_file() { # <repo> <pfad> <lokale-datei> <commit-nachricht>
  local sha; sha=$(api "$FORGEJO/api/v1/repos/$1/contents/$2" | jq -r .sha)
  jq -n --arg c "$(base64 < "$3" | tr -d '\n')" --arg s "$sha" --arg m "$4" \
    '{content: $c, sha: $s, message: $m}' \
    | api -X PUT "$FORGEJO/api/v1/repos/$1/contents/$2" -d @- >/dev/null
}
get_file() { api "$FORGEJO/api/v1/repos/$1/raw/$2"; }

# Kleines Repo aus einer Datei catalog-info.yaml anlegen (über setup/mkrepo.sh)
mk_repo() { # <repo> (Inhalt von catalog-info.yaml auf stdin)
  local tmp; tmp=$(mktemp -d); cat > "$tmp/catalog-info.yaml"
  echo "# ${1#*/}" > "$tmp/README.md"
  "$LAB/setup/mkrepo.sh" "$1" "$tmp" >/dev/null; rm -rf "$tmp"
}

s1() { # Bot-Token in Forgejo widerrufen
  local id; id=$(curl -sf -u "$BOT" "$FORGEJO/api/v1/users/backstage-bot/tokens" \
    | jq -r --arg e "${FORGEJO_TOKEN: -8}" '.[] | select(.token_last_eight == $e).id')
  [ -n "$id" ] || { echo "✘ Token nicht gefunden" >&2; exit 1; }
  curl -sf -u "$BOT" -X DELETE "$FORGEJO/api/v1/users/backstage-bot/tokens/$id"
}
r1() { # nur falls das Token noch ungültig ist: neues erzeugen, Portal neu starten
  if ! curl -sf -H "Authorization: token $FORGEJO_TOKEN" "$FORGEJO/api/v1/user" \
      >/dev/null; then
    rm -f "$LAB/setup/forgejo-token"; "$LAB/setup/up.sh" >/dev/null; restart
  fi
}

s2() { # Gruppe team-sendung in kranich/org umbenennen
  get_file kranich/org org.yaml > "$STATE/org.yaml"
  sed 's/team-sendung$/team-sendungen/; s/team-sendung\]/team-sendungen]/' \
    "$STATE/org.yaml" > "$STATE/org.neu.yaml"
  put_file kranich/org org.yaml "$STATE/org.neu.yaml" \
    "Team Sendung heißt jetzt team-sendungen"
}
r2() {
  [ -f "$STATE/org.yaml" ] || return 0
  put_file kranich/org org.yaml "$STATE/org.yaml" "Zurück zu team-sendung"
  rm -f "$STATE/org.yaml" "$STATE/org.neu.yaml"
}

s3() { # Template in einem Repo außerhalb von kranich/templates
  mk_repo kranich/vorlagen-web <<'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: statische-website
  title: Statische Website
  description: Neue Website mit nginx – vom Team Web
spec:
  owner: team-web
  type: website
  parameters:
    - title: Website
      properties:
        name: { title: Name, type: string }
  steps:
    - id: log
      name: Hallo
      action: debug:log
      input:
        message: Website ${{ parameters.name }}
EOF
}
r3() {
  api -X DELETE "$FORGEJO/api/v1/repos/kranich/vorlagen-web" >/dev/null || true
  # eine eventuell ergänzte Regel (Fix aus Drill 3) wieder entfernen
  yq -i 'del(.catalog.rules[].locations[]
    | select(.pattern == "*kranich/vorlagen-*"))' "$PORTAL/app-config.local.yaml"
}

s4() { # backstage-bot aus dem Owners-Team der Org kranich entfernen
  local team; team=$(api "$FORGEJO/api/v1/orgs/kranich/teams" \
    | jq -r '.[] | select(.name=="Owners").id')
  api -X DELETE "$FORGEJO/api/v1/teams/$team/members/backstage-bot" >/dev/null
}
r4() {
  local team; team=$(api "$FORGEJO/api/v1/orgs/kranich/teams" \
    | jq -r '.[] | select(.name=="Owners").id')
  api -X PUT "$FORGEJO/api/v1/teams/$team/members/backstage-bot" >/dev/null
  # Übungsrepo aus Drill 4 samt Katalog-Location wieder entfernen
  api -X DELETE "$FORGEJO/api/v1/repos/kranich/retouren-api" >/dev/null 2>&1 || true
  for id in $(bs catalog/locations | jq -r '.[].data
      | select(.target | test("/retouren-api/")) | .id'); do
    bs "catalog/locations/$id" -X DELETE || true
  done
}

s5() { # app.extensions in der local-Datei (ersetzt die Liste aus app-config.yaml)
  yq -i '.app.extensions =
    [{"page:app-visualizer": {"config": {"title": "Struktur"}}}]' \
    "$PORTAL/app-config.local.yaml"
  restart
}
r5() {
  if [ "$(yq '.app.extensions' "$PORTAL/app-config.local.yaml")" != "null" ]; then
    yq -i 'del(.app.extensions)' "$PORTAL/app-config.local.yaml"; restart; fi
}

DOCS="$PORTAL/node_modules/@backstage/plugin-techdocs-backend/static/docs"
s6() { # mkdocs aus dem venv entfernen und die gebaute Doku löschen
  mv "$LAB/venv/bin/mkdocs" "$STATE/mkdocs"
  rm -rf "$DOCS/default/component/sendungs-api"
}
r6() {
  if [ -f "$STATE/mkdocs" ] && [ ! -e "$LAB/venv/bin/mkdocs" ]; then
    mv "$STATE/mkdocs" "$LAB/venv/bin/mkdocs"; fi
  rm -f "$STATE/mkdocs"
}

s7() { docker stop "$PG" >/dev/null; }          # Datenbank weg
r7() { # nur falls Postgres nicht antwortet: starten, warten, Portal neu starten
  docker exec "$PG" pg_isready -h 127.0.0.1 -U backstage >/dev/null 2>&1 && return 0
  docker start "$PG" >/dev/null
  until docker exec "$PG" pg_isready -h 127.0.0.1 -U backstage >/dev/null 2>&1; do
    sleep 1; done
  restart
}

s8() { # Kopie von sendungs-api mit gleichem Entity-Namen
  mk_repo kranich/sendungs-api-neu <<'EOF'
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: sendungs-api
  description: Sendungs-API v2 – neue Implementierung in Go
spec:
  type: service
  lifecycle: experimental
  owner: team-sendung
  system: sendungsverfolgung
EOF
}
r8() {
  api -X DELETE "$FORGEJO/api/v1/repos/kranich/sendungs-api-neu" >/dev/null || true
}

ausloesen() { "s$1"; touch "$STATE/aktiv-$1"; }
zuruecksetzen() {
  "r$1"; rm -f "$STATE/aktiv-$1"; echo "✔ Szenario $1 zurückgesetzt"
}

case "${1:-}" in
  [1-8])
    if [ "${2:-}" = "--reset" ]; then zuruecksetzen "$1"
    else ausloesen "$1"; echo "✔ Szenario $1 ausgelöst – viel Erfolg"; fi ;;
  random)
    n=$(( RANDOM % 8 + 1 )); ausloesen "$n" >/dev/null
    echo "✔ Ein zufälliges Szenario ist aktiv. Die Uhr läuft." ;;
  status)
    ls "$STATE" | sed -n 's/^aktiv-/aktiv: Szenario /p'; echo "✔ Status gezeigt" ;;
  reset-all)
    for f in "$STATE"/aktiv-*; do [ -e "$f" ] && zuruecksetzen "${f##*-}"; done
    echo "✔ keine Sabotage mehr aktiv" ;;
  *) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
