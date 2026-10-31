#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 14 (✔/✘). Exit-Code = Anzahl Fehler.
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }

t "config:check ohne Fehler" "cd '$PORTAL' && yarn backstage-cli config:check"
t "Backend bereit (readiness)" \
  "curl -sf $BACKSTAGE/.backstage/health/v1/readiness | jq -e '.status==\"ok\"'"
t "keine Entity mit Processing-Fehler" \
  "bs 'catalog/entities?fields=kind,metadata.name,status' \
     | jq -e '[.[] | select(.status.items)] | length == 0'"
t "keine unverarbeiteten Entities (pending/failed)" \
  "[ \$(bs catalog/entities/unprocessed/pending | jq '.entities|length') = 0 ] &&
   [ \$(bs catalog/entities/unprocessed/failed | jq '.entities|length') = 0 ]"
t "lieferschein-service im Katalog" \
  "bs catalog/entities/by-name/component/default/lieferschein-service"
t "DevTools meldet dieselbe Version wie backstage.json" \
  "[ \"\$(bs devtools/info | jq -r .backstageVersion)\" = \
     \"\$(jq -r .version '$PORTAL/backstage.json')\" ]"
t "Gitea-Provider läuft ohne 401" \
  "! '$LAB/setup/portal.sh' logs 400 | grep -q 'gitea-provider.*401'"
exit "$fail"
