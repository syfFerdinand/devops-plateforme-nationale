# Runbook — Incident post-déploiement

## 1. Qualification (2 min)

| Sévérité | Définition | Réaction |
|---|---|---|
| **P1** | Service indisponible ou parcours usager critique bloqué | Astreinte immédiate, rollback, communication usager |
| **P2** | Dégradation notable, contournement existant | Traitement en heure ouvrée, rollback si non résolu sous 1 h |
| **P3** | Anomalie mineure, pas d'impact usager | Ticket, traitement dans la MEP suivante |

## 2. Première question : est-ce lié au déploiement ?

Ouvrir le tableau de bord SLO et repérer l'annotation de déploiement.
- Dégradation qui **commence** à l'annotation : traiter comme une régression → rollback.
- Dégradation **antérieure** à l'annotation : cause externe (dépendance, charge, infrastructure) → ne pas
  rollbacker, investiguer la cause.

## 3. Séquence de traitement

```
Mitiger (rollback ou feature flag désactivé)  →  Communiquer  →  Investiguer  →  Corriger  →  Post-mortem
```

Le feature flag est le moyen le plus rapide : si la régression provient d'une fonctionnalité sous flag,
la désactiver prend quelques secondes et évite un rollback complet.

## 4. Investigation

```bash
# Quelle version tourne réellement ?
kubectl get rollout <service> -n prod -o jsonpath='{.spec.template.spec.containers[0].image}'

# Événements récents
kubectl get events -n prod --sort-by=.lastTimestamp | tail -30

# Logs d'erreur corrélés
# Loki : {app="<service>", env="prod"} |= "level=error" | json
# Tempo : partir d'un trace_id relevé dans un log d'erreur
```

Points à vérifier dans l'ordre : version déployée, erreurs applicatives, latence des dépendances,
saturation de ressources, état des migrations de base, secrets et certificats expirés.

## 5. Communication

| Destinataire | Quand | Contenu |
|---|---|---|
| Canal #incidents | Immédiat | Service, impact, sévérité, pilote |
| Métier / PO | < 15 min pour un P1 | Impact usager, contournement, estimation de rétablissement |
| Usagers | Si P1 > 30 min | Message de statut, factuel, sans jargon technique |
| Direction | P1 clôturé | Synthèse et actions engagées |

## 6. Post-mortem (obligatoire pour P1 et pour tout rollback)

Sous 5 jours ouvrés, sans recherche de faute. Plan : chronologie, impact usager mesuré, cause racine,
ce qui a fonctionné, ce qui a manqué, actions correctives avec porteur et échéance.
**Sortie obligatoire : au moins une action qui rend cette classe d'incident détectable plus tôt dans le pipeline.**
