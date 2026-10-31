#!/usr/bin/env bash
# seed.sh – legt die Organisation "kranich" und die Demo-Repos aus setup/repos/ an.
# Vorhandene Repos bleiben unangetastet; --reset legt alle frisch an (Stand Tag 0).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
api() { curl -sf -u "$ADMIN" -H 'Content-Type: application/json' "$@"; }
api "$FORGEJO/api/v1/orgs/kranich" >/dev/null || api -X POST "$FORGEJO/api/v1/orgs" \
  -d '{"username":"kranich","full_name":"Kranich Logistik GmbH"}' >/dev/null
# Bot in das Owners-Team der Org, damit Templates dort Repos anlegen dürfen
team=$(api "$FORGEJO/api/v1/orgs/kranich/teams" | jq -r '.[] | select(.name=="Owners").id')
api -X PUT "$FORGEJO/api/v1/teams/$team/members/backstage-bot" >/dev/null
for src in "$DIR"/repos/*/; do
  name=$(basename "$src")
  if [ "${1:-}" = "--reset" ] || ! api "$FORGEJO/api/v1/repos/kranich/$name" >/dev/null
  then
    "$DIR/mkrepo.sh" "kranich/$name" "$src"
  fi
done
echo "✔ Org kranich mit $(ls "$DIR/repos" | wc -l | tr -d ' ') Repos"
