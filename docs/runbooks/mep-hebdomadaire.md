# Runbook — Mise en production hebdomadaire

**Créneau : mardi 10 h – 12 h.** Objectif : une MEP doit être un non-événement.

## J-1 (lundi) — Préparation

- [ ] Le comité de MEP (20 min) valide le contenu et les risques
- [ ] Notes de version générées automatiquement à partir des commits, relues par le PO
- [ ] Tous les critères automatiques sont au vert (voir `docs/08`, §3.1)
- [ ] Stage métier validée par le PO
- [ ] Vérification du budget d'erreur : s'il est épuisé, la MEP est reportée sauf correctif de fiabilité
- [ ] Absence de gel de production en cours
- [ ] Migration de base présente ? Vérifier la compatibilité N-1 et créer le point de restauration

## Jour J — 09 h 45, avant ouverture de la fenêtre

- [ ] Équipe disponible et identifiée (pilote de MEP + un développeur du périmètre)
- [ ] Aucun incident P1 ou P2 en cours
- [ ] Tableau de bord SLO ouvert, référence de latence et d'erreur notée
- [ ] Annonce sur le canal métier

## Jour J — 10 h 00, exécution

1. Créer ou approuver la PR de promotion vers `gitops/overlays/main` (digest validé en stage).
2. Obtenir les 2 approbations (dont une personne n'ayant pas écrit le code).
3. Fusionner. Argo CD synchronise et Argo Rollouts démarre le canary.
4. **Observer** les paliers 5 % → 25 % → 50 % → 100 % (environ 20 minutes).
   L'analyse est automatique : ne pas intervenir sauf demande explicite de pause.
5. À 100 % : exécuter les tests de fumée, vérifier l'annotation Grafana.

## Jour J — après généralisation

- [ ] Surveillance renforcée pendant 2 h, équipe joignable
- [ ] Comparaison des SLI avec la référence notée avant MEP
- [ ] Clôture annoncée sur le canal métier, notes de version diffusées
- [ ] Durée totale et éventuels incidents enregistrés dans le suivi DORA

## En cas d'anomalie

Appliquer `rollback-production.md`. Aucune tentative de correction directe sur le cluster.
