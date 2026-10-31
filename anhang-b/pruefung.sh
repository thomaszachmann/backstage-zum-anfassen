#!/usr/bin/env bash
# pruefung.sh – wertet die Abschlussprüfung aus (Anhang B). Ändert nichts.
# Aufruf: bash ~/backstage-lab/code/anhang-b/pruefung.sh   (Portal muss laufen)
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
PG="${PG:-bs-postgres}"                  # Container aus Tag 13
P="$LAB/pruefung"
FJ="$FORGEJO/api/v1/repos/kranich"
POLICY="$PORTAL/packages/backend/src/modules/permissionPolicy.ts"
declare -a pts=(0 0 0 0 0 0 0 0 0 0 0)
pt() {  # pt <aufgabe> <punkte> <text> <bash-ausdruck>
  if eval "$4" >/dev/null 2>&1; then
    echo "✔ A$1 $3 (+$2)"; pts[$1]=$((pts[$1] + $2))
  else
    echo "✘ A$1 $3 (0 von $2)"
  fi
}
e() { bs "catalog/entities/by-name/$1"; }                  # e kind/namespace/name
has() { e "$1" | jq -e "$2"; }                             # has <ref> <jq-filter>
rel() { has "$1" "any(.relations[]; .type == \"$2\" and .targetRef == \"$3\")"; }
T=group:default/team-fuhrpark
S=system:default/flottenmanagement
TPL=template/default/fuhrpark-service
O=component/default/fahrzeug-ortung
DOCS=techdocs/static/docs/default/component/fahrzeug-ortung
EP='[.. | objects | select(.["ui:field"]? == "EntityPicker")
  | .["ui:options"].catalogFilter.kind] | any(. == "System")'
TASKS='[.tasks[] | select(.status == "completed"
  and .spec.templateInfo.entityRef == "template:default/fuhrpark-service")]'

echo "== Teil 1: Katalog"
pt 1 4 "Group team-fuhrpark (team) unter it" \
  "has group/default/team-fuhrpark '.spec.type == \"team\"' &&
   rel group/default/team-fuhrpark childOf group:default/it"
pt 1 4 "mindestens zwei User in team-fuhrpark" \
  "has group/default/team-fuhrpark '[.relations[] | select(.type == \"hasMember\")]
     | length >= 2'"
pt 1 2 "Team stammt aus kranich/org" \
  "has group/default/team-fuhrpark '.metadata.annotations
     [\"backstage.io/managed-by-origin-location\"] | test(\"/kranich/org/\")'"
pt 2 5 "Domain fuhrpark gehört team-fuhrpark" \
  "rel domain/default/fuhrpark ownedBy $T"
pt 2 5 "System flottenmanagement in Domain fuhrpark" \
  "rel system/default/flottenmanagement partOf domain:default/fuhrpark &&
   rel system/default/flottenmanagement ownedBy $T"
pt 2 5 "Resource fahrzeug-db (database) im System" \
  "has resource/default/fahrzeug-db '.spec.type == \"database\"' &&
   rel resource/default/fahrzeug-db partOf $S"
pt 3 4 "Component fahrzeug-api im System, stellt API bereit" \
  "rel component/default/fahrzeug-api partOf $S &&
   rel component/default/fahrzeug-api providesApi api:default/fahrzeug-api"
pt 3 3 "fahrzeug-api hängt von fahrzeug-db ab" \
  "rel component/default/fahrzeug-api dependsOn resource:default/fahrzeug-db"
pt 3 4 "Component fahrtenbuch-web nutzt die API" \
  "rel component/default/fahrtenbuch-web partOf $S &&
   rel component/default/fahrtenbuch-web consumesApi api:default/fahrzeug-api"
pt 3 4 "API fahrzeug-api: OpenAPI-Definition eingebunden" \
  "has api/default/fahrzeug-api '.spec.type == \"openapi\" and
     (.spec.definition | test(\"^openapi: \"; \"m\"))'"
pt 4 5 "Repo kranich/flottenmanagement per Discovery, nicht registriert" \
  "e component/default/fahrzeug-api && ! bs catalog/locations |
     jq -e 'any(.[]; .data.target | test(\"/kranich/flottenmanagement/\"))'"
pt 4 5 "alle Entities von team-fuhrpark ohne Processing-Fehler" \
  "bs 'catalog/entities?filter=relations.ownedBy=$T&fields=kind,status' |
     jq -e 'length >= 5 and ([.[] | select(.status.items)] | length == 0)'"

echo "== Teil 2: Golden Path"
pt 5 4 "Template fuhrpark-service aus kranich/templates" \
  "has $TPL '.metadata.annotations[\"backstage.io/managed-by-location\"]
     | test(\"/kranich/templates/\")'"
pt 5 4 "EntityPicker für System" "has $TPL '$EP'"
pt 5 4 "Checkbox (boolean) steuert einen Step per if" \
  "has $TPL 'any(.. | objects; .type? == \"boolean\") and
     any(.spec.steps[]; .if)'"
pt 5 3 "publish:gitea und catalog:register" \
  "has $TPL '[.spec.steps[].action] | index(\"publish:gitea\")
     and index(\"catalog:register\")'"
pt 6 3 "Repo kranich/fahrzeug-ortung in Forgejo" \
  "curl -sf -u \$ADMIN $FJ/fahrzeug-ortung"
pt 6 4 "fahrzeug-ortung im System, Owner team-fuhrpark" \
  "rel $O partOf $S && rel $O ownedBy $T"
pt 6 3 "per Template erzeugt (Task completed)" \
  "bs scaffolder/v2/tasks | jq -e '$TASKS | length > 0'"
pt 7 3 "Annotation techdocs-ref an fahrzeug-ortung" \
  "has $O '.metadata.annotations[\"backstage.io/techdocs-ref\"] == \"dir:.\"'"
pt 7 3 "Doku gebaut (techdocs_metadata.json)" \
  "bs techdocs/metadata/techdocs/default/component/fahrzeug-ortung"
pt 7 4 "mindestens zwei Doku-Seiten" \
  "bs $DOCS/search/search_index.json |
     jq -e '[.docs[].location | select(contains(\"#\") | not)] | length >= 2'"
pt 8 3 "Suche findet die Component" \
  "bs 'search/query?term=fahrzeug-ortung&types%5B0%5D=software-catalog' |
     jq -e 'any(.results[]; .document.location
       == \"/catalog/default/component/fahrzeug-ortung\")'"
pt 8 2 "Suche findet die TechDocs" \
  "bs 'search/query?term=fahrzeug-ortung&types%5B0%5D=techdocs' |
     jq -e 'any(.results[]; .document.location | contains(\"fahrzeug-ortung\"))'"

echo "== Teil 3: Plattform"
cfg=$(cd "$PORTAL" && yarn backstage-cli config:print --frontend --format json \
  2>/dev/null)
tools() { jq -e '[.app.extensions[] | objects
  | .["home-page-widget:home/toolkit"] // empty][0].config.tools' <<<"$cfg"; }
SYS=/catalog/default/system/flottenmanagement
pt 9 6 "Toolkit verlinkt das System flottenmanagement" \
  "tools | jq -e 'any(.[]; .url | endswith(\"$SYS\"))'"
pt 9 4 "Toolkit behält dabei den Forgejo-Link" \
  "tools | jq -e 'any(.[]; .url | endswith(\"$SYS\"))
     and any(.[]; .label == \"Forgejo\")'"

echo "== Zusatz (optional, Bonus)"
pt 10 5 "Policy: Löschen von Fuhrpark-Entities nur für team-fuhrpark" \
  "grep -q team-fuhrpark '$POLICY' && grep -q isEntityOwner '$POLICY' &&
   grep -q permissionPolicy '$PORTAL/packages/backend/src/index.ts'"
if docker exec "$PG" pg_isready -q -h 127.0.0.1 -U backstage 2>/dev/null; then
  pt 10 5 "Backup pruefung/catalog.dump enthält fahrzeug-ortung" \
    "docker exec -i $PG pg_restore -f - -a -t final_entities < '$P/catalog.dump' |
       grep -q 'component:default/fahrzeug-ortung'"
else
  echo "– A10 Backup übersprungen: kein Postgres-Container $PG (Tag 13)"
fi

sum=0; for a in 1 2 3 4 5 6 7 8 9; do sum=$((sum + pts[a])); done
echo "Summe: $sum von 100 (Aufgabe 1: ${pts[1]} von 10, Bonus: ${pts[10]} von 10)"
if [ "$sum" -ge 70 ] && [ "${pts[1]}" -eq 10 ]; then echo "✔ BESTANDEN"
else echo "✘ NICHT BESTANDEN"; exit 1; fi
