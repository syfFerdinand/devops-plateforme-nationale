# 06 — Tâche 1 : supervision, SLO et exploitation

> **Implémentation** : les règles, tableaux de bord, routage d'alertes et scripts décrits ici sont
> livrés dans `gitops/observabilite/`, `gitops/base/slo-rules.yaml` et `scripts/`.
> Voir `docs/10-implementation-supervision.md` pour le mode d'emploi.

## 1. Principe

La supervision ne sert pas seulement à constater une panne. Dans cette architecture elle est **un composant
du pipeline** : c'est elle qui décide si un canary est promu ou annulé. Les indicateurs doivent donc être
fiables, disponibles rapidement et définis avant le déploiement.

## 2. Les trois piliers

| Pilier | Outil | Usage principal |
|---|---|---|
| Métriques | Prometheus + Thanos (rétention longue) | SLI, alerting, analyse canary, capacité |
| Logs | Loki | Investigation, logs structurés JSON corrélés au `trace_id` |
| Traces | OpenTelemetry + Tempo | Latence par dépendance, parcours usager de bout en bout |

Corrélation obligatoire : chaque log applicatif porte `trace_id`, `span_id`, `version`, `env`. Depuis une
alerte on atteint la trace, puis les logs de la requête concernée, en deux clics.

## 3. SLI / SLO par service

| SLI | Définition | SLO cible | Budget d'erreur mensuel |
|---|---|---|---|
| Disponibilité | % de requêtes HTTP non 5xx | 99,9 % | 43 min |
| Latence | p95 du temps de réponse des parcours usagers | < 500 ms | 1 % des requêtes au-delà |
| Exactitude | % de transactions métier abouties | 99,95 % | — |
| Fraîcheur | Délai de propagation des données inter-services | < 5 min | — |

**Politique de budget d'erreur** : si le budget mensuel est consommé à plus de 50 % en milieu de mois, les
nouvelles fonctionnalités cèdent la priorité à la fiabilité jusqu'au rétablissement. Cette règle est validée
par la direction ; elle est ce qui empêche la cadence hebdomadaire de dégrader le service.

## 4. Alerting

Principe : **on alerte sur les symptômes perçus par l'usager, pas sur les causes techniques.**

| Alerte | Condition | Sévérité | Destination |
|---|---|---|---|
| Budget d'erreur consommé rapidement | Burn rate > 14,4 sur 1 h (multi-fenêtre) | P1 | Astreinte, appel |
| Latence dégradée | p95 > 2× la référence pendant 10 min | P2 | Canal d'équipe |
| Échec de déploiement | Rollout `Degraded` ou canary abandonné | P1 | Astreinte + auteur de la MEP |
| Dérive GitOps en production | Argo CD `OutOfSync` > 5 min | P2 | Équipe plateforme |
| CVE critique sur image déployée | Détection au re-scan quotidien | P2 | RSSI + équipe |
| Expiration de certificat ou de secret | < 15 jours | P3 | Ticket automatique |
| Saturation de capacité | Utilisation > 80 % pendant 30 min | P3 | Ticket automatique |

Règles de discipline : pas d'alerte sans action associée, pas d'alerte sans runbook lié, revue mensuelle des
alertes déclenchées pour supprimer le bruit. Une alerte ignorée trois fois est soit corrigée, soit supprimée.

## 5. Tableaux de bord

| Tableau de bord | Public | Contenu |
|---|---|---|
| **Service usager** | Métier + exploitation | Disponibilité, latence, volumétrie, taux d'erreur par parcours |
| **SLO & budget d'erreur** | Équipes + direction | Consommation du budget, tendance, incidents |
| **Déploiements (DORA)** | Chef DevOps + direction | Fréquence, délai, taux d'échec, MTTR, avec annotations de MEP |
| **Pipeline** | Équipes | Durée, taux d'échec par étape, temps d'attente, flaky tests |
| **Sécurité** | RSSI | CVE ouvertes par âge, images non signées, exceptions actives |
| **Capacité / coût** | Plateforme | Consommation par namespace, gaspillage de ressources |

**Annotation automatique des déploiements** dans Grafana : chaque MEP apparaît comme une ligne verticale sur
les graphes. C'est le moyen le plus rapide de répondre à « est-ce lié au déploiement de ce matin ? ».

## 6. Traçabilité et conformité

- Journaux d'audit Kubernetes et Vault centralisés, non modifiables, conservés selon la politique d'archivage.
- Chaque déploiement de production est reconstituable : qui, quoi, quand, quel digest, quelle approbation,
  quel résultat d'analyse.
- Export mensuel automatique du registre des changements pour le comité de sécurité.

## 7. Gestion des incidents

```
Détection (alerte ou canary) → Qualification P1..P3 → Mitigation (rollback d'abord)
   → Communication (canal + statut usager) → Résolution → Post-mortem sans recherche de faute (< 5 jours)
   → Actions correctives tracées dans le backlog, avec échéance et porteur
```

Le post-mortem est systématique pour tout P1 et tout rollback. Sa sortie obligatoire est **au moins une action
qui rend cette classe d'incident détectable plus tôt dans le pipeline**. C'est le mécanisme qui fait que le
taux d'échec de changement baisse dans le temps au lieu de stagner.

## 8. Renvois vers l'implémentation

| Section | Fichiers correspondants |
|---|---|
| §2 Trois piliers | `gitops/observabilite/otel-collector.yaml`, `loki-alloy.yaml`, `valeurs-kube-prometheus-stack.yaml` |
| §3 SLI / SLO | `gitops/base/slo-rules.yaml`, `gitops/base/servicemonitor.yaml` |
| §4 Alerting | `gitops/observabilite/prometheus-rules-plateforme.yaml`, `alertmanager-config.yaml` |
| §5 Tableaux de bord | `gitops/observabilite/grafana-dashboards/*.json` |
| §5 Annotation des MEP | `gitops/observabilite/hook-annotation-deploiement.yaml`, `scripts/annoter-deploiement.sh` |
| §7 Gestion des incidents | `docs/runbooks/incident-post-deploiement.md` |
| Indicateurs DORA (`docs/08` §4) | `gitops/observabilite/prometheus-rules-dora.yaml`, `scripts/mesurer-rollback.sh` |
| Tests des alertes | `tests/prometheus/slo-rules-test.yaml`, `.github/workflows/observabilite.yaml` |
