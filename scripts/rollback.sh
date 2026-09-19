#!/usr/bin/env bash
# Rollback assisté de production — implémente docs/runbooks/rollback-production.md
# Usage : ./scripts/rollback.sh <service> [namespace]
set -euo pipefail

SERVICE="${1:?Usage: rollback.sh <service> [namespace]}"
NS="${2:-prod}"
DEBUT=$(date +%s)

echo "═══ Rollback de $SERVICE dans $NS ═══"
echo "Version actuelle : $(kubectl get rollout "$SERVICE" -n "$NS" \
  -o jsonpath='{.spec.template.spec.containers[0].image}')"

read -r -p "Confirmer le retour à la version précédente ? [oui/non] " REPONSE
[[ "$REPONSE" == "oui" ]] || { echo "Annulé."; exit 1; }

echo "→ Étape 2 : rétablissement du service"
kubectl argo rollouts undo "$SERVICE" -n "$NS"
kubectl argo rollouts status "$SERVICE" -n "$NS" --timeout 300s

echo "→ Étape 3 : vérification"
kubectl get pods -n "$NS" -l "app=$SERVICE" -o wide
if [[ -x ./tests/smoke/run.sh ]]; then
  ./tests/smoke/run.sh "https://${SERVICE}.service-public.gouv.tg" || echo "⚠️  Tests de fumée en échec, poursuivre l'investigation."
fi

DUREE=$(( $(date +%s) - DEBUT ))
echo "✅ Service rétabli en ${DUREE}s (objectif < 600s)"

# Publication de la mesure : alimente l'indicateur « durée de retour arrière » (docs/08 §4.2)
./scripts/mesurer-rollback.sh "$SERVICE" "$DUREE" "${TYPE_ROLLBACK:-reel}" || \
  echo "⚠️  Métrique non publiée, à reporter manuellement au post-mortem."
echo
echo "⚠️  ÉTAPE 4 OBLIGATOIRE — sans elle Argo CD redéploiera la version défaillante :"
echo "    cd platform-gitops && git revert <sha-de-la-PR-de-promotion> --no-edit && git push"
echo "⚠️  ÉTAPE 5 — bloquer le digest fautif dans Harbor et créer le ticket de post-mortem."
