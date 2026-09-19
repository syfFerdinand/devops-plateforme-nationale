#!/usr/bin/env bash
# Tests de fumée post-déploiement. Exécutés après chaque synchronisation,
# et par l'AnalysisTemplate sur la version canary avant promotion.
set -euo pipefail
BASE="${1:?Usage: run.sh <base-url>}"
DIGEST_ATTENDU="${2:-}"
ECHECS=0

verifier() {
  local nom="$1" attendu="$2" obtenu="$3"
  if [[ "$obtenu" == "$attendu" ]]; then
    echo "  ✅ $nom"
  else
    echo "  ❌ $nom (attendu: $attendu, obtenu: $obtenu)"
    ECHECS=$((ECHECS + 1))
  fi
}

echo "Tests de fumée sur $BASE"

verifier "Santé applicative" "200" \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$BASE/healthz")"

verifier "Disponibilité au trafic" "200" \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$BASE/readyz")"

verifier "Authentification d'un usager de test" "200" \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
     -H "Authorization: Bearer ${SMOKE_TOKEN:-test}" "$BASE/api/v1/profil")"

verifier "Accès base de données" "ok" \
  "$(curl -s --max-time 5 "$BASE/healthz/dependencies" | jq -r '.database // "absent"')"

verifier "Service aval" "ok" \
  "$(curl -s --max-time 5 "$BASE/healthz/dependencies" | jq -r '.upstream // "absent"')"

if [[ -n "$DIGEST_ATTENDU" ]]; then
  verifier "Version déployée conforme au digest promu" "$DIGEST_ATTENDU" \
    "$(curl -s --max-time 5 "$BASE/version" | jq -r '.digest // "inconnu"')"
fi

echo
if [[ $ECHECS -eq 0 ]]; then
  echo "✅ Tests de fumée réussis."
  exit 0
fi
echo "❌ $ECHECS test(s) en échec — critère d'abandon A4, appliquer le runbook de rollback."
exit 1
