# ADR-0005 — Trunk-based development et feature flags

- **Statut** : accepté
- **Date** : semaine 1

## Contexte
L'objectif est une cadence hebdomadaire. Un modèle de branches à longue durée de vie produit des lots de
changements volumineux, des fusions conflictuelles et un risque élevé par mise en production.

## Décision
Branches de moins de deux jours, intégration continue sur `main`, fonctionnalités inachevées livrées
désactivées derrière un feature flag (Unleash).

## Conséquences
- **Positives** : les lots restent petits, donc le risque par MEP baisse ; le déploiement est découplé de
  l'activation, ce qui permet d'activer une fonctionnalité sans MEP et de la désactiver sans rollback ;
  la mise en production devient un acte technique banal.
- **Négatives** : discipline exigeante (`main` doit rester déployable en permanence) ; les feature flags
  constituent une dette s'ils ne sont pas supprimés (règle : suppression obligatoire dans les 60 jours suivant
  l'activation complète, suivie par un contrôle automatisé).
