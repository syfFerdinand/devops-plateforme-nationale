# ADR-0004 — Gestion des secrets par Vault et External Secrets Operator

- **Statut** : accepté
- **Date** : semaine 3

## Contexte
Des secrets sont manipulés manuellement pendant les MEP et potentiellement présents dans des dépôts ou des
interfaces de CI. Contexte de service public : traçabilité des accès et rotation exigées.

## Options envisagées
1. **Secrets Kubernetes seuls** : encodés en base64, non chiffrés au repos par défaut, non rotables, non auditables.
2. **SOPS + age dans Git** : chiffré, compatible GitOps, mais rotation manuelle et secrets chiffrés exposés dans l'historique.
3. **Vault + External Secrets Operator** : coffre centralisé, rotation, identifiants dynamiques, journal d'audit.

## Décision
Vault + ESO. SOPS + age retenu uniquement comme solution transitoire si la mise à disposition de Vault est retardée.
La CI s'authentifie par OIDC, sans secret longue durée.

## Conséquences
- **Positives** : aucun secret dans Git ; rotation automatisée ; identifiants de base de données dynamiques à
  durée de vie courte ; journal d'audit des accès ; aucun geste manuel de secret pendant une MEP.
- **Négatives** : Vault devient un composant critique (haute disponibilité et sauvegarde obligatoires) ;
  procédure de descellement à maîtriser ; coût d'exploitation supplémentaire.
