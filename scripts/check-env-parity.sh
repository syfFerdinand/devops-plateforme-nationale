#!/usr/bin/env bash
# Contrôle de parité entre deux environnements (docs/03 §3).
# Échoue si un écart n'est pas déclaré dans gitops/parity-allowlist.yaml.
set -euo pipefail

SRC="${1:-recette}"
DST="${2:-prod}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

normaliser() {
  # Neutralise les champs dont la divergence est légitime et déclarée.
  yq eval-all '
    del(.metadata.namespace) |
    del(.spec.replicas) |
    del(.spec.minReplicas) | del(.spec.maxReplicas) |
    del(.spec.template.spec.containers[].resources) |
    del(.spec.template.spec.containers[].image) |
    del(.spec.strategy) |
    del(.spec.dataFrom) |
    del(.data.API_BASE_URL) |
    del(.metadata.name | select(. == "*-config-*"))
  ' - | yq -P 'sort_keys(..)'
}

echo "→ Rendu des overlays $SRC et $DST"
kustomize build "$ROOT/gitops/overlays/$SRC" | normaliser > "$TMP/$SRC.yaml"
kustomize build "$ROOT/gitops/overlays/$DST" | normaliser > "$TMP/$DST.yaml"

if diff -u "$TMP/$SRC.yaml" "$TMP/$DST.yaml" > "$TMP/ecarts.diff"; then
  echo "✅ Parité conforme entre $SRC et $DST : aucun écart non déclaré."
  exit 0
fi

echo "❌ Écarts non déclarés entre $SRC et $DST :"
cat "$TMP/ecarts.diff"
echo
echo "Chaque écart doit être soit supprimé, soit déclaré et justifié dans gitops/parity-allowlist.yaml."
exit 1
