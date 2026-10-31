#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 15 (✔/✘): alle acht Sabotagen behoben?
# Exit-Code = Anzahl Fehler.
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
PG="${PG:-bs-postgres}"
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
fj() { curl -sf -H "Authorization: token $FORGEJO_TOKEN" "$FORGEJO/api/v1/$1"; }
fehlt() { ! curl -sf -u "$ADMIN" "$FORGEJO/api/v1/repos/kranich/$1"; }

t "Keine Sabotage mehr aktiv" "! ls $LAB/tag15/.sabotage/aktiv-* "
t "1 Bot-Token gültig" "fj user | jq -e '.login == \"backstage-bot\"'"
t "1 Keine Processing-Errors an Locations" \
  "bs 'catalog/entities?filter=kind=location' \
     | jq -e '[.[].status.items[]?] | length == 0'"
t "2 Gruppe team-sendung im Katalog" \
  "bs catalog/entities/by-name/group/default/team-sendung"
t "3 Kein Repo kranich/vorlagen-web mehr" "fehlt vorlagen-web"
t "4 Bot darf Repos in kranich anlegen (Owners)" \
  "fj user/orgs | jq -e 'map(.username) | index(\"kranich\")'"
t "5 Keine app.extensions in der local-Datei" \
  "[ \"\$(yq '.app.extensions' $PORTAL/app-config.local.yaml)\" = null ]"
t "6 mkdocs im PATH" "command -v mkdocs"
t "7 PostgreSQL ($PG) bereit" "docker exec $PG pg_isready -h 127.0.0.1 -U backstage"
t "8 Kein Repo kranich/sendungs-api-neu mehr" "fehlt sendungs-api-neu"
exit "$fail"
