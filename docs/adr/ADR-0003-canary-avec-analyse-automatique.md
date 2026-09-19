# ADR-0003 — Déploiement canary avec analyse automatique et rollback automatique

- **Statut** : accepté
- **Date** : semaine 6

## Contexte
Quatre incidents post-déploiement en deux mois, dont deux restaurations. Le déploiement expose actuellement
100 % des usagers simultanément, et la détection dépend d'un signalement humain.

## Options envisagées
1. **Rolling update + supervision** : insuffisant, l'exposition reste totale.
2. **Blue/green** : bascule instantanée réversible, mais expose aussi 100 % des usagers et double le coût en ressources.
3. **Canary avec analyse automatique (Argo Rollouts)** : exposition progressive, décision automatisée.

## Décision
Canary en production, blue/green en recette (pour éprouver la bascule), rolling update en développement.

## Conséquences
- **Positives** : l'exposition maximale en cas de défaut tombe à 5 % des usagers ; la détection ne dépend plus
  d'un humain ; le rollback intervient en moins de 2 minutes.
- **Négatives** : le déploiement dure plus longtemps (environ 20 minutes) ; deux versions coexistent, donc les
  changements doivent être rétrocompatibles (API et schéma de données) ; les SLI doivent être fiables, sous
  peine de faux rollbacks.
