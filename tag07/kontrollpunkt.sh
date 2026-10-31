#!/usr/bin/env bash
# kontrollpunkt.sh – Tag 7: TechDocs (✔/✘). Exit-Code = Anzahl Fehler.
source ~/backstage-lab/setup/env.sh
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
DOCS=techdocs/static/docs/default/component/sendungs-api
t "mkdocs aus dem venv im PATH" "command -v mkdocs | grep -q '/venv/bin/mkdocs'"
t "mkdocs-techdocs-core installiert" "pip show mkdocs-techdocs-core"
t "Generator läuft lokal (runIn: local)" \
  "grep -A2 '^  generator:' '$PORTAL/app-config.local.yaml' | grep -q 'runIn: local'"
t "Annotation techdocs-ref an sendungs-api" \
  "bs catalog/entities/by-name/component/default/sendungs-api \
     | jq -e '.metadata.annotations[\"backstage.io/techdocs-ref\"] == \"dir:.\"'"
t "Metadaten: Site Sendungs-API gebaut" \
  "bs techdocs/metadata/techdocs/default/component/sendungs-api \
     | jq -e '.site_name == \"Sendungs-API\"'"
t "Startseite index.html ausgeliefert" "bs $DOCS/index.html"
t "Seite Betrieb mit Admonition" \
  "bs $DOCS/betrieb/index.html | grep -q 'admonition note'"
exit "$fail"
