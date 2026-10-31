#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 1 (✔/✘). Exit-Code = Anzahl Fehler.
source ~/backstage-lab/setup/env.sh
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
e() { bs "catalog/entities/by-name/$1"; }

t "Component sendungs-api im Katalog" "e component/default/sendungs-api"
t "API sendungs-api im Katalog" "e api/default/sendungs-api"
t "Component tracking-web im Katalog" "e component/default/tracking-web"
t "tracking-web konsumiert die API" \
  "e component/default/tracking-web | jq -e '.relations[] |
     select(.type==\"consumesApi\" and .targetRef==\"api:default/sendungs-api\")'"
t "Neue Beschreibung angekommen (Refresh)" \
  "e component/default/sendungs-api | jq -e '.metadata.description | test(\"Zustell\")'"
t "Zwei Forgejo-Locations registriert" \
  "[ \$(bs catalog/locations | jq '[.[].data.target | select(test(\"/kranich/\"))]
     | length') -ge 2 ]"
exit "$fail"
