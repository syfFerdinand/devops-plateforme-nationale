# 00 — Diagnostic, causes racines et décisions de correction

## 1. Constats de départ

| # | Constat | Conséquence mesurable |
|---|---|---|
| C1 | Des interventions manuelles subsistent en mise en production | MEP non reproductible, dépendance à des personnes, pas de traçabilité |
| C2 | 4 incidents post-déploiement en 2 mois, 2 restaurations de version | Taux d'échec de changement estimé > 25 %, confiance dégradée |
| C3 | Écarts de configuration entre dev, stage et production | « Ça marchait en stage » : la stage ne valide plus rien |
| C4 | Cadence de MEP faible et irrégulière | Lots de changements volumineux, donc risque par MEP élevé |
| C5 | Pas de retour arrière outillé | MTTR long, décision de rollback prise tardivement et à la main |

## 2. Analyse des causes racines

### C1 — Interventions manuelles
Le déploiement est déclenché par un opérateur qui applique des manifestes et ajuste des paramètres au moment
de la MEP. Deux causes : absence de source de vérité unique pour l'état du cluster, et paramètres
d'environnement saisis au dernier moment plutôt que versionnés.

### C2 — Incidents post-déploiement
Trois mécanismes se cumulent :
- **Absence de porte de qualité bloquante** : un défaut détectable en CI atteint la production.
- **Déploiement en tout-ou-rien** : 100 % des usagers sont exposés simultanément au changement.
- **Absence de validation automatique après déploiement** : l'incident est découvert par l'usager, pas par le système.

### C3 — Écarts de configuration
L'image ou les manifestes sont reconstruits par environnement, la configuration est dupliquée au lieu d'être
dérivée d'une base commune, et des modifications correctives sont appliquées directement sur le cluster sans
retour dans Git (dérive de configuration, ou *drift*).

### C4/C5 — Cadence et retour arrière
La peur de la MEP fait grossir les lots, ce qui augmente le risque par MEP, ce qui renforce la peur.
Boucle classique. Le seul moyen de la casser est de rendre le retour arrière **banal, rapide et testé**.

## 3. Décisions de correction

| ID | Décision | Répond à | Effet attendu |
|---|---|---|---|
| D1 | Artefact unique immuable, promu par **digest** (`sha256:…`) de dev à prod | C1, C3 | Ce qui est validé en stage est exactement ce qui part en main |
| D2 | **GitOps pull-based** (Argo CD), suppression des droits d'écriture humains en prod | C1, C3 | MEP reproductible, auditable, drift détecté et corrigé |
| D3 | **Quality gates bloquants** en CI (tests, couverture, SAST, SCA, scan image, politiques) | C2 | Les défauts connus n'atteignent plus la production |
| D4 | **Déploiement progressif canary** avec analyse automatique des SLI | C2, C5 | Exposition limitée à 5–10 % des usagers en cas de défaut |
| D5 | **Retour arrière automatisé** (`revert` Git + `argo rollouts undo`) documenté et répété | C5 | Rollback < 10 min, décision prise par le système avant l'humain |
| D6 | **Configuration hiérarchisée** (base Kustomize + overlays) et parité d'environnements contrôlée | C3 | Écart d'environnement = anomalie détectée en CI |
| D7 | **Secrets hors Git** (Vault + External Secrets Operator), OIDC pour la CI | C1 | Aucun secret manipulé à la main lors d'une MEP |
| D8 | **Trunk-based + feature flags**, lots de changements petits et fréquents | C4 | Risque par MEP réduit, cadence hebdomadaire atteignable |
| D9 | **Migrations de base expand/contract**, compatibles N-1 | C5 | Le rollback applicatif ne casse jamais le schéma de données |
| D10 | **Supervision orientée SLO** avec alerting sur budget d'erreur et annotation des déploiements | C2, C5 | Corrélation immédiate entre une MEP et une dégradation |

## 4. Traçabilité constat → décision → indicateur

```
C1 manuel ────► D1 D2 D7 ────► % de MEP entièrement automatisées (cible 100 %)
C2 incidents ─► D3 D4 D10 ───► Taux d'échec de changement (cible < 10 %)
C3 écarts ────► D1 D2 D6 ────► Nb d'écarts de configuration détectés (cible 0 non intentionnel)
C4 cadence ───► D8 ──────────► Fréquence de déploiement (cible >= 1/semaine, viser 1/jour en dev)
C5 rollback ──► D4 D5 D9 ────► Délai de retour arrière (cible < 10 min) et MTTR (cible < 30 min)
```
