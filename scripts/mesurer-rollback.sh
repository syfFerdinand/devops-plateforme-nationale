#!/usr/bin/env bash
# Publie la durée réelle d'un retour arrière.
# Appelé par scripts/rollback.sh et lors de l'exercice mensuel.
# Un objectif de rollback < 10 min qui n'est jamais mesuré n'est pas un objectif.
set -euo pipefail
SERVICE="${1:?service}" ; DUREE="${2:?duree en secondes}" ; TYPE="${3:-reel}"
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://prometheus-pushgateway.monitoring.svc:9091}"

cat <<METRICS | curl -sf --data-binary @- \
  "$PUSHGATEWAY_URL/metrics/job/rollback/service/$SERVICE/type/$TYPE"
# TYPE rollback_duree_secondes gauge
rollback_duree_secondes{service="$SERVICE",type="$TYPE"} $DUREE
# TYPE deploiement_rollback_total counter
deploiement_rollback_total{service="$SERVICE",env="prod",type="$TYPE"} 1
METRICS

echo "✅ Durée de rollback publiée : ${DUREE}s (objectif < 600s)"
[[ "$DUREE" -gt 600 ]] && echo "⚠️  Objectif dépassé — à inscrire au post-mortem." || true
