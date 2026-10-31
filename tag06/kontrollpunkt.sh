#!/usr/bin/env bash
# kontrollpunkt.sh – Kontrollpunkt Tag 6 (✔/✘). Exit-Code = Anzahl Fehler.
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
R=$FORGEJO/api/v1/repos/kranich

t "Eigene Action kranich:ticket:create installiert" \
  "bs scaffolder/v2/actions | jq -e '.[] | select(.id==\"kranich:ticket:create\")'"
t "Filter parseRepoUrl verfügbar" \
  "bs scaffolder/v2/templating-extensions | jq -e '.filters.parseRepoUrl'"
t "Template kranich-service registriert" \
  "bs catalog/entities/by-name/template/default/kranich-service"
t "lager-scanner: config/prod.json (each) und CI-Workflow (if)" \
  "curl -sf -u \$ADMIN \$R/lager-scanner/contents/config/prod.json \
   && curl -sf -u \$ADMIN \$R/lager-scanner/contents/.forgejo/workflows/ci.yaml"
t "lager-scanner: TICKET.md aus der eigenen Action" \
  "curl -sf -u \$ADMIN \$R/lager-scanner/raw/TICKET.md | grep -q '^# KRA-'"
t "Component lager-scanner gehört zum System sendungsverfolgung" \
  "bs catalog/entities/by-name/component/default/lager-scanner \
     | jq -e '.spec.system==\"system:default/sendungsverfolgung\"'"
t "Abgebrochener Task hat kein Repo lager-abbruch erzeugt" \
  "! curl -sf -u \$ADMIN \$R/lager-abbruch"
exit "$fail"
