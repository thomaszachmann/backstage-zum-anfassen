#!/usr/bin/env bash
# loesung.sh – spielt die Musterlösung von Anhang B nach (Aufgabe 1–9 und Backup).
# Die Policy aus Aufgabe 10 ist Code und bleibt Handarbeit. Laufzeit ca. 3 min.
set -euo pipefail
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
L="$(cd "$(dirname "$0")" && pwd)"
P="$LAB/pruefung"; PG="${PG:-bs-postgres}"
G="http://$ADMIN@127.0.0.1:$FORGEJO_PORT/kranich"
push() { git add -A && git -c user.name="Lab Admin" -c user.email=admin@lab.local \
  commit -qm "$1" && git push -q origin main; }
warte() { for _ in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return; sleep 5; done
  echo "✘ Zeitüberschreitung: $1" >&2; exit 1; }
mkdir -p "$P" && cd "$P" && rm -rf org templates

# A1: Team und User in kranich/org
git clone -q "$G/org.git"
grep -q team-fuhrpark org/org.yaml || cat "$L/org/team-fuhrpark.yaml" >> org/org.yaml
(cd org && push "Team Fuhrpark" || true)
# A2–A4: eigenes Repo, die Discovery findet es ohne Registrierung
"$LAB/setup/mkrepo.sh" kranich/flottenmanagement "$L/flottenmanagement"
# A5: Template neben node-service
git clone -q "$G/templates.git"
cp -R "$L/fuhrpark-service" templates/
grep -q fuhrpark-service templates/templates.yaml \
  || echo '    - ./fuhrpark-service/template.yaml' >> templates/templates.yaml
(cd templates && push "Template fuhrpark-service" || true)
bs catalog/refresh -X POST -H 'Content-Type: application/json' \
  -d '{"entityRef":"location:default/kranich-templates"}'
warte "bs catalog/entities/by-name/template/default/fuhrpark-service"
warte "bs catalog/entities/by-name/system/default/flottenmanagement"
echo "✔ A1–A5: Team, Domain-Repo und Template im Katalog"
# A6: Service per Template anlegen (Lab-Token, umgeht die Policy aus Tag 12)
ID=$(bs scaffolder/v2/tasks -X POST -H 'Content-Type: application/json' \
  -d @"$L/werte.json" | jq -r .id)
warte "bs scaffolder/v2/tasks/$ID | jq -e '.status == \"completed\"'"
echo "✔ A6: Task $ID completed"
# A7: Doku bauen wie beim Öffnen des Tabs
bs techdocs/sync/default/component/fahrzeug-ortung -N -m 180 >/dev/null || true
warte "bs techdocs/metadata/techdocs/default/component/fahrzeug-ortung"
echo "✔ A7: TechDocs gebaut"
# A9: Toolkit-Link vor den Forgejo-Eintrag in app-config.yaml
SYS=/catalog/default/system/flottenmanagement
if ! grep -q "$SYS" "$PORTAL/app-config.yaml"; then
  awk -v s="$SYS" '/- url: http:\/\/127\.0\.0\.1:3300\/kranich$/ && !d {
      i = $0; sub(/-.*/, "", i); d = 1
      print i "- url: " s; print i "  label: Flottenmanagement"
      print i "  icon: kind:system" } 1' "$PORTAL/app-config.yaml" > "$P/app-config.neu"
  mv "$P/app-config.neu" "$PORTAL/app-config.yaml"
fi
echo "✔ A9: Toolkit-Link eingetragen (wirksam nach portal.sh restart)"
# A10 (Zusatz): Sicherung der Katalog-Datenbank, falls Postgres läuft (Tag 13)
if docker exec "$PG" pg_isready -q -h 127.0.0.1 -U backstage 2>/dev/null; then
  docker exec "$PG" pg_dump -U backstage -Fc backstage_plugin_catalog \
    > "$P/catalog.dump"
  echo "✔ A10: $P/catalog.dump"
fi
echo "Suche (A8): Index läuft jede Minute – vor pruefung.sh ca. 2 min warten."
