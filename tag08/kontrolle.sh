#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 8 (✔/✘). Exit-Code = Anzahl Fehler.
source ~/backstage-lab/setup/env.sh
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
q() { bs "search/query?term=$1"; }

t "Suche liefert die API sendungs-api" \
  "q sendung | jq -e '.results[] | select(.type==\"software-catalog\"
     and .document.kind==\"API\" and .document.title==\"sendungs-api\")'"
t "Suche liefert TechDocs-Treffer" \
  "q bereitschaft | jq -e '.results[] | select(.type==\"techdocs\")'"
t "Katalog-Kollator läuft jede Minute" \
  "grep -q 'search_index_software_catalog.*PT1M' $LAB/portal.log"
for typ in openapi asyncapi graphql; do
  t "API vom Typ $typ im Katalog" \
    "bs 'catalog/entities?filter=kind=api,spec.type=$typ' | jq -e 'length > 0'"
done
t "sendungs-ereignisse: Definition aus Datei geladen" \
  "bs catalog/entities/by-name/api/default/sendungs-ereignisse |
     jq -e '.spec.definition | startswith(\"asyncapi: 3.0.0\")'"
t "tracking-web konsumiert sendungs-graphql" \
  "bs catalog/entities/by-name/api/default/sendungs-graphql | jq -e '.relations[] |
     select(.type==\"apiConsumedBy\" and
       .targetRef==\"component:default/tracking-web\")'"
exit "$fail"
