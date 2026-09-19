# 02 — Tâche 1 : étapes du pipeline et contrôles qualité

## 1. Vue synthétique des étapes

| # | Étape | Déclencheur | Bloquant | Durée cible |
|---|---|---|---|---|
| 0 | Pre-commit local (format, lint, gitleaks) | `git commit` | Oui (local) | < 10 s |
| 1 | Validation statique : lint, format, `kubeconform`, `conftest` | PR | Oui | 2 min |
| 2 | Tests unitaires + couverture | PR | Oui | 5 min |
| 3 | Analyse qualité SonarQube (quality gate) | PR | Oui | 3 min |
| 4 | SAST (Semgrep) + secret scan (Gitleaks) | PR | Oui | 3 min |
| 5 | SCA dépendances (Trivy fs) + licences | PR | Oui (High/Critical) | 2 min |
| 6 | Build image OCI reproductible + SBOM (Syft) | PR et `main` | Oui | 5 min |
| 7 | Scan de l'image (Trivy image) | PR et `main` | Oui (High/Critical) | 2 min |
| 8 | Signature Cosign keyless + attestation de provenance | `main` | Oui | 1 min |
| 9 | Push registry + PR automatique de promotion DEV | `main` | Oui | 1 min |
| 10 | Déploiement DEV (Argo CD) + tests de fumée | merge GitOps | Oui | 3 min |
| 11 | Tests d'intégration + contrat (Pact) | après 10 | Oui | 6 min |
| 12 | Tests E2E Playwright | après 11 | Oui | 8 min |
| 13 | Promotion RECETTE + blue/green | auto | Oui | 3 min |
| 14 | Tests de performance k6 + DAST ZAP | nuit | Oui (seuils) | 25 min |
| 15 | Recette métier + test de rollback | J+1 | Oui | manuel |
| 16 | PR de promotion PROD (2 approbations, fenêtre) | hebdomadaire | Oui | — |
| 17 | Canary + analyse automatique | merge | Auto-rollback | 20 min |
| 18 | Smoke tests prod + annotation Grafana + notes de version | après 17 | Non | 2 min |

**Temps de traversée visé (commit → prod)** : moins de 2 heures de temps machine, cadence de MEP hebdomadaire
en phase 1, quotidienne à terme. **Boucle de retour au développeur : moins de 15 minutes** (étapes 1 à 7).

## 2. Contrôles qualité et seuils

| Contrôle | Outil | Seuil bloquant | Justification |
|---|---|---|---|
| Couverture du code modifié | SonarQube | >= 80 % sur le diff | Évite d'exiger 80 % sur le legacy, exige la qualité sur le neuf |
| Duplication | SonarQube | < 3 % sur le diff | Maintenabilité |
| Bugs / vulnérabilités Sonar | SonarQube | 0 `Blocker`, 0 `Critical` | Défauts déterministes |
| Vulnérabilités dépendances | Trivy fs | 0 `CRITICAL`, 0 `HIGH` exploitable | CVE connues et corrigeables |
| Vulnérabilités image de base | Trivy image | 0 `CRITICAL` | Images `distroless`/`chainguard` pour réduire la surface |
| Secrets | Gitleaks | 0 détection | Fuite = rotation immédiate |
| Politiques Kubernetes | Conftest/Kyverno CLI | 0 violation | Limites, probes, non-root, digest |
| Tests unitaires | Jest/JUnit/pytest | 0 échec, 0 test ignoré non justifié | — |
| Tests E2E parcours critiques | Playwright | 0 échec sur les parcours usagers prioritaires | Protège le service rendu |
| Performance | k6 | p95 < 500 ms, taux d'erreur < 1 % à 2× la charge nominale | Prévient les régressions de latence |
| Accessibilité | axe-core / Pa11y | 0 violation `critical` RGAA | Obligation légale pour un service public |
| DAST | OWASP ZAP baseline | 0 alerte `High` | Contrôle boîte noire avant prod |

### Gestion des exceptions
Toute dérogation à un seuil bloquant est explicite, datée, justifiée et limitée dans le temps
(fichier `.trivyignore` / `.semgrepignore` avec date d'expiration obligatoire). Une exception expirée
refait échouer le pipeline. Revue mensuelle des exceptions par le Chef DevOps et le RSSI.

## 3. Détail des étapes sensibles

### 3.1 Build reproductible
- Dockerfile multi-étages, image finale `distroless`, exécution `non-root`, système de fichiers en lecture seule.
- `SOURCE_DATE_EPOCH` fixé, dépendances épinglées (lockfiles), cache de couches par branche.
- Étiquettes OCI obligatoires : `org.opencontainers.image.revision`, `.source`, `.version`, `.created`.
- **Une seule construction pour toute la chaîne** : la référence utilisée ensuite est le digest, jamais un tag mutable.

### 3.2 Traçabilité de la chaîne d'approvisionnement
```
code (commit signé)
  └─ build (runner éphémère, identité OIDC)
       ├─ SBOM CycloneDX  (Syft)      → attaché à l'image dans Harbor
       ├─ signature       (Cosign keyless, identité = workflow GitHub)
       └─ attestation de provenance SLSA niveau 3
            └─ vérifiée à l'admission par Kyverno avant tout démarrage de pod
```
Objectif : **aucune image non signée, non scannée ou non traçable ne peut s'exécuter sur le cluster**, même
en cas de compromission d'un compte.

### 3.3 Tests de contrat entre services
La plateforme expose plusieurs services interdépendants. Les tests de contrat (Pact) évitent qu'un changement
d'API d'un service casse un consommateur : le contrat est publié par le consommateur, vérifié par le
producteur dans sa propre CI. Un producteur ne peut pas être promu s'il rompt un contrat en vigueur en production.

### 3.4 Tests de fumée post-déploiement
Exécutés systématiquement après chaque synchronisation, sur tous les environnements :
santé applicative, authentification d'un usager de test, appel d'un service aval, accès base, version déployée
conforme au digest attendu. Un échec en production déclenche le rollback.

## 4. Gestion des runners CI

- Runners **éphémères**, un job = une machine détruite après exécution (aucun état partagé, aucune persistance de secret).
- Runners auto-hébergés dans un réseau maîtrisé pour les jobs ayant besoin d'accéder au registre interne et à Vault.
- Aucun secret statique : authentification par **OIDC** vers Vault, Harbor et le fournisseur cloud.
- Séparation des jobs de confiance (build, signature) et des jobs traitant du code non fiable (PR de l'extérieur).

## 5. Implémentation de référence

Voir `.github/workflows/` :
- `ci.yaml` — étapes 1 à 9
- `cd-promotion.yaml` — promotion entre environnements par PR automatisée
- `security-scheduled.yaml` — re-scan quotidien des images déployées (CVE publiées après le build)
- `pr-preview.yaml` — environnement éphémère par PR
