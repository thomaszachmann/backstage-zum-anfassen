#!/usr/bin/env bash
# dryrun.sh <template-ref> <verzeichnis> <werte.json> – Dry-Run per Scaffolder-API.
# Template-Definition aus dem Katalog, Dateien aus dem lokalen Verzeichnis.
set -euo pipefail
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
[ $# -eq 3 ] || { echo "Aufruf: dryrun.sh <ref> <dir> <werte.json>" >&2; exit 2; }
ref="${1#template:}"; dir="$(cd "$2" && pwd)"
files=$(cd "$dir" && find . -type f ! -path './.git/*' | sed 's|^\./||' | sort \
  | while read -r f; do
      jq -n --arg p "$f" --arg c "$(base64 < "$f" | tr -d '\n')" \
        '{path: $p, base64Content: $c}'
    done | jq -s .)
template=$(bs "catalog/entities/by-name/template/$ref")
jq -n --argjson t "$template" --argjson f "$files" --slurpfile v "$3" \
  '{template: $t, values: $v[0], directoryContents: $f}' \
  | bs scaffolder/v2/dry-run -X POST -H 'Content-Type: application/json' -d @-
