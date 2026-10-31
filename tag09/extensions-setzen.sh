#!/usr/bin/env bash
# extensions-setzen.sh <datei> – ersetzt die Liste app.extensions in
# $PORTAL/app-config.yaml durch den Inhalt von <datei> (eine YAML-Liste).
set -euo pipefail
[ $# -eq 1 ] || { echo "Aufruf: extensions-setzen.sh <datei>" >&2; exit 2; }
src="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
cd "${PORTAL:?vorher: source ~/backstage-lab/setup/env.sh}"
cp app-config.yaml app-config.yaml.bak
awk -v f="$src" '
  /^  extensions:/ { print; while ((getline l < f) > 0) print "    " l; skip = 1; next }
  skip && /^[^ #]/ { skip = 0; print "" }
  !skip' app-config.yaml.bak > app-config.yaml
echo "✔ app.extensions aus $(basename "$src") übernommen" \
  "(Sicherung: app-config.yaml.bak)"
