#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 9 (✔/✘). Exit-Code = Anzahl Fehler.
source ~/backstage-lab/setup/env.sh
cd "$PORTAL" || exit 1
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
# wirksame Frontend-Konfiguration (alle app-config*.yaml zusammengeführt)
cfg=$(yarn backstage-cli config:print --frontend --format json 2>/dev/null)
ext() { jq -e --arg id "$1" \
  '[.app.extensions[] | select(type == "object" and has($id)) | .[$id]][0]' <<<"$cfg"; }

t "Frontend liefert Titel Kranich Entwicklerportal" \
  "curl -sf $APP/ | grep -q '<title>Kranich Entwicklerportal</title>'"
t "Keine app.extensions in app-config.local.yaml" \
  "! grep -q '^  extensions:' app-config.local.yaml"
t "page:home liegt auf /" "ext page:home | jq -e '.config.path == \"/\"'"
t "page:catalog nicht mehr auf / umgebogen" "! ext page:catalog"
t "Random Joke abgeschaltet" \
  "ext home-page-widget:home/random-joke | jq -e '. == false'"
t "Toolkit verlinkt Forgejo" \
  "ext home-page-widget:home/toolkit | jq -e '.config.tools[] |
     select(.label == \"Forgejo\")'"
t "Weltuhr zeigt Berlin" \
  "ext home-page-widget:home/world-clock | jq -e '.config.clockConfigs[] |
     select(.timeZone == \"Europe/Berlin\")'"
t "Logo mit Schriftzug Kranich" \
  "grep -q 'Kranich' packages/app/src/modules/nav/LogoFull.tsx"
t "Kranich-Theme in App.tsx registriert" \
  "grep -q themeModule packages/app/src/App.tsx"
t "@backstage/theme als Abhängigkeit deklariert" \
  "jq -e '.dependencies[\"@backstage/theme\"]' packages/app/package.json"
exit "$fail"
