#!/usr/bin/env bash
# owner-check.sh – listet Owner-Referenzen, zu denen es keine Entity gibt.
source ~/backstage-lab/setup/env.sh
refs=$(bs 'catalog/entity-facets?facet=relations.ownedBy' \
  | jq -c '[.facets[][] | .value]')
bs catalog/entities/by-refs -X POST -H 'Content-Type: application/json' \
  -d "{\"entityRefs\":$refs,\"fields\":[\"kind\"]}" \
  | jq -r --argjson r "$refs" '[range(0; $r | length) as $i
      | select(.items[$i] == null) | "✘ fehlt: \($r[$i])"]
      | if length == 0 then "✔ alle \($r | length) Owner vorhanden" else .[] end'
