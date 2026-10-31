#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 13 (✔/✘). Exit-Code = Anzahl Fehler.
# Erwartet: Produktions-Backend läuft auf :7007, Postgres im Container bs-postgres.
source ~/backstage-lab/setup/env.sh
PG="${PG:-bs-postgres}"
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
sql() { docker exec "$PG" psql -U backstage -d "$1" -Atc "$2"; }

t "PostgreSQL im Container $PG bereit" \
  "docker exec $PG pg_isready -h 127.0.0.1 -U backstage"
t "Eigene Datenbank für den Katalog" \
  "sql postgres \"select 1 from pg_database where datname='backstage_plugin_catalog'\" \
     | grep -qx 1"
t "Entities liegen in Postgres" \
  "[ \$(sql backstage_plugin_catalog 'select count(*) from final_entities') -gt 0 ]"
t "Suchindex in Postgres (Tabelle documents)" \
  "[ \$(sql backstage_plugin_search 'select count(*) from documents') -gt 0 ]"
t "Backend bereit (readiness)" \
  "curl -sf $BACKSTAGE/.backstage/health/v1/readiness | jq -e '.status == \"ok\"'"
t "Backend liefert das Frontend aus" "curl -sf $BACKSTAGE/ | grep -q '<title>'"
t "Katalog-API liefert User aus Postgres" \
  "bs 'catalog/entities?filter=kind=user' | jq -e 'length > 0'"
t "Kein Klartext-Passwort in app-config.production.yaml" \
  "grep -q 'password: \${POSTGRES_PASSWORD}' $PORTAL/app-config.production.yaml"
exit "$fail"
