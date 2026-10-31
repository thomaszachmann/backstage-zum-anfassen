#!/usr/bin/env bash
# kontrollpunkt.sh – Kontrollpunkt Tag 5 (✔/✘). Exit-Code = Anzahl Fehler.
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }

t "Action publish:gitea installiert" \
  "bs scaffolder/v2/actions | jq -e '.[] | select(.id==\"publish:gitea\")'"
t "Template node-service registriert (Owner plattform)" \
  "bs catalog/entities/by-name/template/default/node-service \
     | jq -e '.spec.owner==\"plattform\"'"
t "Beispiel-Template ausgeblendet" \
  "! bs catalog/entities/by-name/template/default/example-nodejs-template"
t "Letzter Task completed" \
  "bs 'scaffolder/v2/tasks?limit=1' | jq -e '.tasks[0].status==\"completed\"'"
t "Repo kranich/lager-api mit catalog-info.yaml" \
  "curl -sf -u \$ADMIN \
     \$FORGEJO/api/v1/repos/kranich/lager-api/contents/catalog-info.yaml"
t "Component lager-api im Katalog (Owner team-sendung)" \
  "bs catalog/entities/by-name/component/default/lager-api \
     | jq -e '.spec.owner==\"group:default/team-sendung\"'"
exit "$fail"
