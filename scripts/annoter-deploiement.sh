#!/usr/bin/env sh
# Annoter un déploiement dans Grafana et publier les métriques DORA.
# Exécuté automatiquement en hook PostSync d'Argo CD.
# Sans cette annotation, corréler une dégradation avec une MEP prend des minutes
# au lieu de quelques secondes (docs/06 §5).
set -eu

SERVICE="${SERVICE:?SERVICE requis}"
ENV="${ENV:?ENV requis}"
GRAFANA_URL="${GRAFANA_URL:-http://grafana.monitoring.svc}"
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://prometheus-pushgateway.monitoring.svc:9091}"

# --- Informations sur la version déployée -----------------------------------
IMAGE=$(kubectl get rollout "$SERVICE" -n "$ENV" \
  -o jsonpath='{.spec.template.spec.containers[0].image}')
DIGEST=$(echo "$IMAGE" | sed 's/.*@//')
REVISION=$(kubectl get rollout "$SERVICE" -n "$ENV" \
  -o jsonpath='{.metadata.annotations.app\.kubernetes\.io/revision}' 2>/dev/null || echo "inconnue")
COMMIT=$(kubectl get rollout "$SERVICE" -n "$ENV" \
  -o jsonpath='{.metadata.annotations.org\.opencontainers\.image\.revision}' 2>/dev/null || echo "inconnu")
MAINTENANT=$(date +%s)

# --- 1. Annotation Grafana --------------------------------------------------
curl -sf -X POST "$GRAFANA_URL/api/annotations" \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"time\": $((MAINTENANT * 1000)),
    \"tags\": [\"deploiement\", \"$ENV\", \"$SERVICE\"],
    \"text\": \"Déploiement $SERVICE · révision $REVISION · commit ${COMMIT}<br/>digest $DIGEST\"
  }" > /dev/null && echo "✅ Annotation Grafana posée"

# --- 2. Métriques DORA ------------------------------------------------------
# Délai de traversée : écart entre l'horodatage du commit et la mise en production.
HORODATAGE_COMMIT=$(kubectl get rollout "$SERVICE" -n "$ENV" \
  -o jsonpath='{.metadata.annotations.org\.opencontainers\.image\.created\.epoch}' 2>/dev/null || echo "")

{
  echo "# TYPE deploiement_horodatage gauge"
  echo "deploiement_horodatage{service=\"$SERVICE\",env=\"$ENV\"} $MAINTENANT"
  if [ -n "$HORODATAGE_COMMIT" ]; then
    echo "# TYPE deploiement_delai_traversee_secondes gauge"
    echo "deploiement_delai_traversee_secondes{service=\"$SERVICE\",env=\"$ENV\"} $((MAINTENANT - HORODATAGE_COMMIT))"
  fi
} | curl -sf --data-binary @- \
    "$PUSHGATEWAY_URL/metrics/job/deploiement/service/$SERVICE/env/$ENV" \
  && echo "✅ Métriques DORA publiées"

# --- 3. Notification au canal métier ---------------------------------------
if [ -n "${SLACK_WEBHOOK:-}" ] && [ "$ENV" = "prod" ]; then
  curl -sf -X POST "$SLACK_WEBHOOK" -H 'Content-Type: application/json' \
    -d "{\"text\": \"🚀 *$SERVICE* déployé en production (révision $REVISION). Tableau de bord : $GRAFANA_URL/d/slo-usagers\"}" \
    > /dev/null
fi
