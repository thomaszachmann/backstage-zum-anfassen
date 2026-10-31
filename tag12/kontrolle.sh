#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 12 (✔/✘). Exit-Code = Anzahl Fehler.
source ~/backstage-lab/setup/env.sh
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
# Token des Gasts (user:development/guest) – ein User ohne Gruppen
GUEST=$(curl -s -H 'X-Requested-With: XMLHttpRequest' \
  "$BACKSTAGE/api/auth/guest/refresh" | jq -r .backstageIdentity.token)
authz() { curl -sf -H "Authorization: Bearer $GUEST" \
  -H 'Content-Type: application/json' "$BACKSTAGE/api/permission/authorize" \
  -d "{\"items\":[{\"id\":\"1\",\"permission\":{\"type\":\"basic\",
       \"name\":\"$1\",\"attributes\":{}}}]}" | jq -r '.items[0].result'; }

t "OAuth2-App Backstage in Forgejo" \
  "curl -sf -u \$ADMIN \$FORGEJO/api/v1/user/applications/oauth2 |
     jq -e '.[] | select(.name==\"Backstage\")'"
t "Forgejo-User anna.berger und thomas.zachmann" \
  "curl -sf -u \$ADMIN \$FORGEJO/api/v1/users/anna.berger &&
   curl -sf -u \$ADMIN \$FORGEJO/api/v1/users/thomas.zachmann"
t "auth/oidc/start leitet zu Forgejo um" \
  "curl -s -o /dev/null -w '%{redirect_url}' \
     '$BACKSTAGE/api/auth/oidc/start?env=development' |
     grep -q '^$FORGEJO/login/oauth/authorize'"
t "Gast darf lesen (catalog.entity.read = ALLOW)" \
  "[ \"\$(authz catalog.entity.read)\" = ALLOW ]"
t "Gast darf keine Templates ausführen (scaffolder.task.create = DENY)" \
  "[ \"\$(authz scaffolder.task.create)\" = DENY ]"
t "Lab-Token lab-cli liest weiter den Katalog" "bs 'catalog/entities?limit=1'"
exit "$fail"
