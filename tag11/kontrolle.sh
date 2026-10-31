#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 11 (✔/✘). Exit-Code = Anzahl Fehler.
source ~/backstage-lab/setup/env.sh
cd "$PORTAL" || exit 99
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }

t "Backend-Plugin in packages/backend/src/index.ts" \
  "grep -q \"@internal/backstage-plugin-bereitschaft-backend'\" \
     packages/backend/src/index.ts"
t "Frontend-Plugin als Abhängigkeit von packages/app" \
  "jq -e '.dependencies[\"@internal/backstage-plugin-bereitschaft\"]' \
     packages/app/package.json"
t "Karte nutzt EntityCardBlueprint mit Filter kind=component" \
  "grep -q \"filter: { kind: 'component' }\" plugins/bereitschaft/src/plugin.tsx"
t "Karte in app-config.yaml als info konfiguriert" \
  "grep -A2 'entity-card:bereitschaft/heute' app-config.yaml | grep -q 'type: info'"
t "Ohne Token: 401" \
  "[ \$(curl -s -o /dev/null -w '%{http_code}' \
     \$BACKSTAGE/api/bereitschaft/heute?team=team-sendung) = 401 ]"
t "Mit Lab-Token: Person aus team-sendung" \
  "bs 'bereitschaft/heute?team=team-sendung' |
     jq -e '.person | test(\"anna.berger|ben.kraus\")'"
t "Unbekanntes Team: 404" \
  "[ \$(bs 'bereitschaft/heute?team=team-xyz' -o /dev/null -w '%{http_code}') \
     = 404 ]"
exit "$fail"
