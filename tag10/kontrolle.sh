#!/usr/bin/env bash
# kontrolle.sh – Kontrollpunkt Tag 10 (✔/✘). Exit-Code = Anzahl Fehler.
source ~/backstage-lab/setup/env.sh
export KUBECONFIG=~/backstage-lab/tag10/kubeconfig
fail=0
t() { if eval "$2" >/dev/null 2>&1; then echo "✔ $1"
  else echo "✘ $1"; fail=$((fail+1)); fi; }
k8s() { bs kubernetes/services/sendungs-api -X POST \
  -H 'Content-Type: application/json' \
  -d '{"entity":{"kind":"Component","metadata":{"name":"sendungs-api"}}}'; }

t "kind-Cluster backstage-lab läuft" "kubectl get nodes"
t "ServiceAccount darf Pods lesen" \
  "kubectl auth can-i list pods --as=system:serviceaccount:backstage:backstage \
     | grep -qx yes"
t "Backstage kennt den Cluster backstage-lab" \
  "bs kubernetes/clusters | jq -e '.items[] | select(.name==\"backstage-lab\")'"
t "Annotation kubernetes-id an sendungs-api" \
  "bs catalog/entities/by-name/component/default/sendungs-api \
     | jq -e '.metadata.annotations[\"backstage.io/kubernetes-id\"]'"
t "Backend liefert Pods ohne Fehler" \
  "k8s | jq -e '.items[0].errors == [] and
     ([.items[0].resources[] | select(.type==\"pods\") | .resources[]] | length > 0)'"
t "Proxy /forgejo liefert Repos der Org kranich" \
  "bs proxy/forgejo/orgs/kranich/repos | jq -e 'length > 0'"
exit "$fail"
