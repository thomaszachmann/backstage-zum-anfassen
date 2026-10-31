#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 4 (✔/✘). Exit-Code = Anzahl Fehler.
source ~/backstage-lab/setup/env.sh
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
e() { bs "catalog/entities/by-name/$1"; }

t "Gruppen kranich, it, team-sendung, team-web, plattform" \
  "for g in kranich it team-sendung team-web plattform; do
     e group/default/\$g || exit 1; done"
t "team-sendung hängt unter it" \
  "e group/default/team-sendung | jq -e '.relations[] |
     select(.type==\"childOf\" and .targetRef==\"group:default/it\")'"
t "User thomas.zachmann mit E-Mail" \
  "e user/default/thomas.zachmann | jq -e '.spec.profile.email | test(\"@\")'"
t "team-sendung besitzt die Component sendungs-api" \
  "bs 'catalog/entities?filter=relations.ownedBy=group:default/team-sendung' |
     jq -e '.[] | select(.metadata.name==\"sendungs-api\" and .kind==\"Component\")'"
t "Keine fehlenden Owner" \
  "bash ~/backstage-lab/tag04/owner-check.sh | grep -q '^✔'"
t "Gast tritt als user:default/thomas.zachmann auf" \
  "curl -sf -H 'X-Requested-With: XMLHttpRequest' \$BACKSTAGE/api/auth/guest/refresh |
     jq -e '.backstageIdentity.identity.userEntityRef ==
       \"user:default/thomas.zachmann\"'"
exit "$fail"
