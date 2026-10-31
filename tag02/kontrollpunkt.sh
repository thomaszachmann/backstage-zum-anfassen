#!/usr/bin/env bash
# kontrollpunkt.sh – prüft den Endstand von Tag 2 per Backstage-API (✔/✘)
source ~/backstage-lab/setup/env.sh
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
       else echo "✘ $1"; fail=$((fail+1)); fi; }
sys='system:default/sendungsverfolgung'
t "Domain logistik vorhanden" "bs catalog/entities/by-name/domain/default/logistik"
t "System liegt in Domain logistik" \
  "bs catalog/entities/by-name/system/default/sendungsverfolgung \
     | jq -e '.spec.domain == \"logistik\"'"
t "System hat 3 Components" \
  "bs 'catalog/entities?filter=kind=component,relations.partOf=$sys' \
     | jq -e 'length == 3'"
t "Resource sendungs-db (type database)" \
  "bs catalog/entities/by-name/resource/default/sendungs-db \
     | jq -e '.spec.type == \"database\"'"
t "Zwei Components hängen von sendungs-db ab" \
  "bs 'catalog/entities?filter=relations.dependsOn=resource:default/sendungs-db' \
     | jq -e 'length == 2'"
t "Keine Processing-Fehler im System" \
  "bs 'catalog/entities?filter=spec.system=sendungsverfolgung' \
     | jq -e '[.[] | select(.status.items)] | length == 0'"
exit "$fail"
