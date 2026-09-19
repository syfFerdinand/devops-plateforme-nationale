# 05 — Tâche 1 : stratégie de déploiement et retour arrière

## 1. Stratégie par environnement

| Environnement | Stratégie | Motif |
|---|---|---|
| Développement | Rolling update | Vitesse, coût minimal |
| Stage | Blue/green | Valide la bascule et la procédure de retour arrière avant la production |
| Production | **Canary avec analyse automatique** | Limite l'exposition des usagers, détecte la régression avant généralisation |

## 2. Déroulé d'un déploiement de production

| Palier | Trafic | Durée | Condition de passage |
|---|---|---|---|
| 1 | 5 % | 5 min | Taux de succès >= 99,5 %, p95 <= référence + 20 % |
| 2 | 25 % | 5 min | Idem + absence d'alerte critique |
| 3 | 50 % | 5 min | Idem |
| 4 | 100 % | — | Validation finale + tests de fumée |

L'analyse est effectuée automatiquement par Argo Rollouts à partir de requêtes Prometheus
(`gitops/argocd/analysis-template.yaml`). **En cas d'échec d'un palier, le retour arrière est immédiat et
automatique, sans intervention humaine.** L'équipe est notifiée après coup, pas pendant.

Une pause manuelle (`pause: {}`) peut être insérée avant le palier 100 % pour les MEP sensibles, afin de
conserver un point de décision humain explicite.

## 3. Retour arrière : trois niveaux

| Niveau | Mécanisme | Délai | Quand |
|---|---|---|---|
| **N1 — Automatique** | Argo Rollouts abandonne le canary sur échec d'analyse | **< 2 min** | Dégradation détectée par les SLI pendant le déploiement |
| **N2 — Assisté** | `kubectl argo rollouts undo` puis `git revert` de la PR de promotion | **< 10 min** | Problème constaté après généralisation |
| **N3 — Restauration complète** | Retour à un état Git antérieur + restauration de données si nécessaire | < 4 h (RTO) | Corruption de données, incident majeur |

### Règle d'or
Un retour arrière **n'est jamais une décision négociée en réunion**. Le déclencheur est défini à l'avance dans
le runbook : si les critères d'échec sont atteints, on revient en arrière d'abord, on analyse ensuite.

### N2 en pratique
```bash
# 1. Stopper l'hémorragie (immédiat, action opérationnelle tracée)
kubectl argo rollouts undo app-usagers -n main
kubectl argo rollouts status app-usagers -n main

# 2. Rétablir la cohérence entre Git et le cluster (obligatoire dans la foulée)
git revert <sha-de-la-PR-de-promotion> && git push
# Argo CD réconcilie : l'état Git redevient la vérité, pas de drift résiduel
```
L'étape 2 est impérative : sans elle, Argo CD redéploierait la version défaillante à la prochaine synchronisation.

## 4. Migrations de base de données : la contrainte qui casse les rollbacks

Un rollback applicatif ne peut pas être rapide si le schéma de données n'est plus compatible avec la version
précédente. C'est la cause la plus fréquente de restauration longue.

**Règle : toute migration est compatible avec la version N-1 (modèle expand / contract).**

```
MEP S1  (expand)    : ajout de la nouvelle colonne, nullable, sans contrainte
                      → code N et N-1 fonctionnent tous les deux
MEP S1  (code)      : le code écrit dans l'ancienne ET la nouvelle colonne, lit l'ancienne
MEP S2  (code)      : le code lit la nouvelle colonne
MEP S3  (contract)  : suppression de l'ancienne colonne, une fois N-1 hors de portée
```

Contraintes appliquées :
- Aucune suppression ni renommage de colonne dans la même MEP que le code qui l'utilise.
- Migrations idempotentes, exécutées par un Job Kubernetes en `preSync`, avec verrou.
- Migration longue (index sur grande table) exécutée hors fenêtre de MEP, en mode concurrent.
- Sauvegarde vérifiée et point de restauration créé avant toute migration `contract`.
- Un contrôle de CI signale toute migration destructive et exige une justification explicite.

## 5. Disponibilité pendant le déploiement

- `PodDisruptionBudget` : `minAvailable: 70 %`.
- `maxUnavailable: 0`, `maxSurge: 1` : aucune capacité perdue pendant la bascule.
- `preStop` avec délai de grâce et arrêt propre (drainage des connexions en cours).
- `terminationGracePeriodSeconds` cohérent avec la durée maximale d'une requête.
- Probes distinctes : `readiness` conditionne le trafic, `liveness` conditionne le redémarrage, `startup`
  protège les démarrages lents.

## 6. Fenêtre de mise en production

| Paramètre | Valeur retenue |
|---|---|
| Créneau | Mardi 10 h – 12 h (heure ouvrée, équipes disponibles) |
| Motif | Un incident en heure ouvrée est traité en minutes, pas en heures |
| Gel | Périodes de forte affluence usagers définies avec le métier (échéances déclaratives, rentrée…) |
| MEP d'urgence | Possible hors fenêtre, procédure accélérée à 1 approbation, post-mortem obligatoire |
| Communication | Notification automatique au canal métier à l'ouverture et à la clôture |

À mesure que la confiance s'installe (taux d'échec de changement stable sous 10 % pendant 4 semaines), la
fenêtre s'élargit puis disparaît au profit du déploiement à la demande.

## 7. Test du retour arrière

Le rollback est **testé à chaque passage en stage** (la stratégie blue/green rend la bascule inverse triviale)
et **exercé en production une fois par mois** sur un service non critique, chronométré. Un mécanisme de secours
jamais exercé est un mécanisme dont on ignore s'il fonctionne.
