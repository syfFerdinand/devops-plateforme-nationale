# Runbook — Retour arrière en production

> **Objectif : rétablir le service en moins de 10 minutes.**
> Ce runbook s'exécute sans réunion préalable. On rétablit d'abord, on analyse ensuite.

## 1. Déclencheurs (un seul suffit)

- Le canary a été abandonné automatiquement par Argo Rollouts.
- Taux de succès < 99,5 % ou p95 > référence + 20 % sur 5 minutes après généralisation.
- Alerte P1 sur un parcours usager critique.
- Échec des tests de fumée post-déploiement.
- Signalement métier d'une régression fonctionnelle bloquante.

## 2. Décision

| Situation | Action | Qui décide |
|---|---|---|
| Canary en cours | Aucune : le rollback est automatique | Système |
| Version généralisée, impact usager | Rollback immédiat | Astreinte, sans validation préalable |
| Impact limité, contournement existant | Correction en avant (fix forward) possible | Chef DevOps |
| Suspicion de corruption de données | **Ne pas rollbacker seul** : passer en incident majeur | Chef DevOps + DBA |

## 3. Procédure — niveau 2 (rollback assisté)

**Étape 1 — Annoncer (30 s)**
```
Canal #incidents : "Rollback en cours sur <service> en production. Déclencheur : <…>. Pilote : <nom>."
```

**Étape 2 — Rétablir le service (2 min)**
```bash
kubectl argo rollouts undo <service> -n main
kubectl argo rollouts status <service> -n main --watch
kubectl get pods -n main -l app=<service> -o wide
```

**Étape 3 — Vérifier (2 min)**
```bash
./tests/smoke/run.sh https://<service>.service-public.gouv.tg
# Contrôler le tableau de bord SLO : taux d'erreur et latence doivent revenir à la référence
```

**Étape 4 — Rétablir la cohérence Git (obligatoire, 3 min)**
```bash
cd platform-gitops
git revert <sha-de-la-PR-de-promotion> --no-edit
git push origin main
argocd app get <service>-main   # doit repasser Synced / Healthy
```
> Sans cette étape, Argo CD redéploiera la version défaillante à la prochaine synchronisation.

**Étape 5 — Clôturer (2 min)**
- Confirmer le rétablissement sur le canal, indiquer l'heure de retour à la normale.
- Bloquer la promotion du digest fautif (étiquette `blocked` dans Harbor).
- Créer le ticket de post-mortem (obligatoire sous 5 jours ouvrés).

## 4. Cas particulier — migration de base appliquée

1. Vérifier la compatibilité N-1 de la migration (elle devrait l'être : politique expand/contract).
2. Si compatible : rollback applicatif standard, la migration reste en place.
3. Si incompatible : **incident majeur**. Mode dégradé ou maintenance, restauration à partir du point de
   restauration créé avant migration, puis reprise des transactions depuis les journaux.
4. Post-mortem obligatoire avec action corrective sur le contrôle CI des migrations destructives.

## 5. Après l'incident

- [ ] Post-mortem rédigé sous 5 jours, sans recherche de faute
- [ ] Au moins une action rendant cette classe de défaut détectable plus tôt dans le pipeline
- [ ] Runbook mis à jour si une étape a manqué ou a été imprécise
- [ ] Durée réelle du rollback enregistrée dans le suivi des indicateurs

## 6. Exercice mensuel

Le premier mardi de chaque mois, rollback volontaire d'un service non critique en production, chronométré,
avec procès-verbal. Objectif : maintenir la procédure vivante et les personnes entraînées.
