# Règles de contribution et de livraison

## Modèle de branches : trunk-based

- `main` est la seule branche de long terme, toujours déployable.
- Branches de travail courtes (`feat/`, `fix/`, `chore/`), durée de vie **< 2 jours**.
- Intégration par Pull Request, squash-merge, 1 revue obligatoire (2 pour un composant critique).
- Les fonctionnalités non terminées sont livrées **désactivées par feature flag**, jamais gardées en branche.

## Convention de commit

`type(scope): description` — types : `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `build`, `ci`, `chore`.
Les commits `feat` et `fix` alimentent la génération automatique des notes de version (SemVer).

## Règles de protection de `main`

| Règle | Valeur |
|---|---|
| Push direct | Interdit |
| Revues requises | 1 minimum, 2 pour `gitops/overlays/prod` (CODEOWNERS) |
| Checks obligatoires | `lint`, `test-unit`, `sast`, `sca`, `build-image`, `policy-check` |
| Historique | Linéaire, signature des commits requise |
| Secrets détectés | Blocage immédiat, rotation obligatoire du secret exposé |

## Définition de terminé (Definition of Done)

- [ ] Tests unitaires ajoutés, couverture du diff >= 80 %
- [ ] Aucune vulnérabilité `HIGH`/`CRITICAL` introduite
- [ ] Migration de base compatible avec la version N-1 (expand/contract)
- [ ] Indicateurs et logs structurés exposés pour la nouvelle fonctionnalité
- [ ] Documentation et feature flag renseignés
- [ ] Procédure de retour arrière identifiée
