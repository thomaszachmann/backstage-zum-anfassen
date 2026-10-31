#!/usr/bin/env bash
# kontrollpunkt.sh – Kontrollpunkt Tag 0 (✔/✘)
source "${LAB:-$HOME/backstage-lab}/setup/env.sh"
cd "$PORTAL" || exit 1
[ "$(jq -r .version backstage.json)" = 1.55.0 ] && echo "✔ Backstage 1.55.0" \
  || echo "✘ falsche Backstage-Version"
jq -e '.resolutions["@yarnpkg/core"] == "4.9.1"' package.json >/dev/null \
  && echo "✔ @yarnpkg/core auf 4.9.1 gepinnt" || echo "✘ resolutions fehlt"
git check-ignore -q app-config.local.yaml && echo "✔ app-config.local.yaml ignoriert" \
  || echo "✘ app-config.local.yaml würde eingecheckt"
[ -s "$LAB/data/catalog.sqlite" ] && echo "✔ Katalog in SQLite ($LAB/data)" \
  || echo "✘ keine SQLite-Datei"
n=$(bs 'catalog/entities?filter=kind=component' | jq length)
[ "${n:-0}" -ge 1 ] && echo "✔ $n Component(s) im Katalog" || echo "✘ Katalog leer"
code=$(curl -s -o /dev/null -w '%{http_code}' "$BACKSTAGE/api/catalog/entities")
[ "$code" = 401 ] && echo "✔ ohne Token: 401" || echo "✘ ohne Token: $code"
"$LAB/setup/check.sh" >/dev/null && echo "✔ check.sh ohne Fehler" \
  || echo "✘ check.sh meldet Fehler"
