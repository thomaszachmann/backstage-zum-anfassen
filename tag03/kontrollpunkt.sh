#!/usr/bin/env bash
# kontrollpunkt.sh – Kontrollpunkt Tag 3 (✔/✘)
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
ok() { echo "✔ $1"; }; nok() { echo "✘ $1"; }
grep -q catalog-backend-module-gitea "$PORTAL/packages/backend/src/index.ts" \
  && ok "Gitea-Provider im Backend" || nok "backend.add(...gitea) fehlt"
n=$(bs catalog/locations | jq length)
[ "$n" = 0 ] && ok "keine per API registrierten Locations mehr" \
  || nok "$n Location(s) noch per API registriert"
for c in sendungs-api tracking-web sendungs-worker; do
  bs "catalog/entities/by-name/component/default/$c" >/dev/null \
    && ok "Component $c im Katalog" || nok "Component $c fehlt"
done
bs catalog/entities/by-name/location/default/kranich-extern >/dev/null \
  && ok "Sammel-Location kranich-extern" || nok "Location kranich-extern fehlt"
bs catalog/entities/by-name/resource/default/paketdienst >/dev/null \
  && ok "Resource paketdienst aus kranich/katalog" || nok "paketdienst fehlt"
e=$(bs 'catalog/entities?fields=kind,metadata.name,status' \
  | jq '[.[] | select(.status.items)] | length')
[ "$e" = 0 ] && ok "keine Processing-Fehler" || nok "$e Entity(s) mit Fehlern"
o=$(bs 'catalog/entities?filter=metadata.annotations.backstage.io/orphan=true' \
  | jq length)
[ "$o" = 0 ] && ok "keine Orphans" || nok "$o Orphan(s)"
