# Industrialisation et sécurisation des déploiements — Plateforme nationale de services numériques

> Livrable DevOps — rôle : **Chef DevOps Senior**
> Objectif direction : **mises en production hebdomadaires**, **réduction des régressions**, **retour arrière rapide**.

---

## 1. Résumé exécutif

La plateforme fonctionne mais sa chaîne de livraison est artisanale : des gestes manuels subsistent en production,
les environnements divergent, et quatre incidents post-déploiement ont été enregistrés en deux mois (dont deux
restaurations de version). Ces trois faits sont liés : **une MEP manuelle sur des environnements non identiques
produit mécaniquement des régressions et rend le retour arrière lent et risqué**.

La cible proposée repose sur cinq décisions structurantes :

1. **Un artefact unique, immuable, promu par empreinte (digest)** de dev jusqu'en production. On ne reconstruit
   jamais une image pour un nouvel environnement.
2. **GitOps en mode « pull »** (Argo CD) : l'état désiré du cluster est dans Git, le cluster se synchronise seul.
   Plus aucun accès `kubectl` humain en production en fonctionnement nominal.
3. **Des quality gates bloquants** dans la CI (tests, couverture, SAST, SCA, scan d'image, politiques) : ce qui
   ne passe pas les contrôles ne peut pas atteindre la production.
4. **Un déploiement progressif (canary) avec analyse automatique** et **retour arrière automatique** en moins
   de 5 minutes si les indicateurs de service se dégradent.
5. **Une supervision qui décide** : les mêmes SLI servent à alerter l'astreinte et à promouvoir ou annuler
   un déploiement canary. Il n'existe pas deux définitions concurrentes de « le service va mal ».
6. **Des secrets hors du code**, gérés par un coffre-fort (Vault) et injectés par External Secrets Operator,
   avec authentification de la CI par OIDC sans secret longue durée.

Cible mesurée à 3 mois : **1 MEP par semaine minimum**, **taux d'échec de changement < 10 %**, **MTTR < 30 min**,
**délai de rollback < 10 min**, **0 écart de configuration non intentionnel entre environnements**.

---

## 2. Contenu du dépôt

| Chemin | Contenu |
|---|---|
| `docs/00-diagnostic-et-resolutions.md` | Diagnostic, causes racines, décisions de correction |
| `docs/01-architecture-cible.md` | **Tâche 1** — architecture cible et syfFerdinand de la chaîne |
| `docs/02-pipeline-cicd.md` | **Tâche 1** — étapes détaillées du pipeline et contrôles qualité |
| `docs/03-environnements-et-configuration.md` | **Tâche 1** — gestion des environnements, suppression des écarts |
| `docs/04-securite-et-secrets.md` | **Tâche 1** — sécurité applicative, chaîne d'approvisionnement, secrets |
| `docs/05-deploiement-et-rollback.md` | **Tâche 1** — stratégie de déploiement, rollback, base de données |
| `docs/06-supervision-et-slo.md` | **Tâche 1** — supervision, SLO, alerting, traçabilité |
| `docs/07-plan-transformation-90-jours.md` | **Tâche 2** — plan 3 mois, priorités, séquencement |
| `docs/08-raci-risques-criteres-kpi.md` | **Tâche 2** — responsabilités, risques, critères de MEP, indicateurs |
| `docs/09-ameliorations-complementaires.md` | Améliorations au-delà du périmètre strict (platform engineering, FinOps, PRA, chaos) |
| `docs/10-implementation-supervision.md` | Mode d'emploi de la chaîne d'observabilité implémentée |
| `docs/adr/` | Décisions d'architecture tracées (ADR) |
| `docs/runbooks/` | Procédures opérationnelles : rollback, incident post-MEP, MEP hebdomadaire |
| `.github/workflows/` | Implémentation de référence de la CI/CD |
| `gitops/` | Manifestes Kustomize + Argo CD / Argo Rollouts (base + overlays par environnement) |
| `gitops/observabilite/` | Socle de supervision : règles SLO, alerting, DORA, tableaux de bord, traces, logs |
| `policies/kyverno/` | Politiques d'admission (signature d'image, digest obligatoire, sécurité des pods) |
| `tests/` | Tests de charge k6, tests de fumée post-déploiement, tests unitaires des règles d'alerte |
| `scripts/` | Outillage : rollback assisté, vérification de parité d'environnements |

## 3. Lecture rapide selon le profil

- **Direction / sponsor** : §1 de ce document, puis `docs/07` et `docs/08`.
- **Architecte / RSSI** : `docs/01`, `docs/04`, `policies/`.
- **Équipes de développement** : `docs/02`, `docs/03`, `docs/05`, `CONTRIBUTING.md`.
- **Exploitation / astreinte** : `docs/05`, `docs/06`, `docs/10`, `docs/runbooks/`.

## 4. Hypothèses de travail

Faute d'accès au système réel, les hypothèses suivantes sont posées et devront être confirmées en semaine 1 :

- Cluster Kubernetes managé ou sur site, version supportée (>= 1.28), 3 environnements distincts.
- Applications conteneurisées, bases de données relationnelles avec migrations applicatives.
- Forge Git disponible (GitHub / GitLab). L'implémentation de référence utilise GitHub Actions ; les principes
  sont transposables à GitLab CI (voir `docs/adr/ADR-0002-choix-outillage.md`).
- Contexte de service public : exigences RGPD, homologation de sécurité, journalisation et traçabilité des
  actions de production.

## 5. Publication sur GitHub

```bash
git init && git add . && git commit -m "feat: chaîne CI/CD cible et plan de transformation DevOps"
git branch -M main
git remote add origin git@github.com:<syfFerdinand>/devops-plateforme-nationale.git
git push -u origin main
```
