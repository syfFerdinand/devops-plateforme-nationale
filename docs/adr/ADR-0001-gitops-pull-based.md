# ADR-0001 — Adopter GitOps en mode « pull » avec Argo CD

- **Statut** : accepté
- **Date** : semaine 1
- **Décideurs** : Chef DevOps, équipe plateforme, RSSI

## Contexte
Les mises en production comportent des interventions manuelles. Il n'existe pas de source de vérité unique de
l'état des clusters, ce qui explique à la fois la non-reproductibilité des MEP et les écarts entre environnements.

## Options envisagées
1. **CI qui pousse** (`kubectl apply` depuis le pipeline) : simple, mais exige des identifiants de production
   dans la CI, ne détecte pas la dérive, et l'état réel n'est jamais comparé à un état désiré.
2. **GitOps pull-based (Argo CD)** : un agent dans le cluster réconcilie en continu l'état Git et l'état réel.
3. **Flux** : équivalent fonctionnel, interface visuelle moins complète, intégration Argo Rollouts moins directe.

## Décision
Argo CD, en mode pull, avec un dépôt GitOps distinct des dépôts applicatifs.

## Conséquences
- **Positives** : la CI n'a plus besoin d'accès en écriture au cluster de production ; la dérive est détectée et
  corrigée ; l'historique de production est l'historique Git ; le rollback devient un `git revert` ;
  l'auditabilité est native.
- **Négatives** : un composant supplémentaire à exploiter ; les équipes doivent apprendre le modèle de promotion
  par PR ; le débogage passe par l'état de synchronisation plutôt que par un journal de déploiement linéaire.
