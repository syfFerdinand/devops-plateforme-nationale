# 03 — Tâche 1 : gestion des environnements et suppression des écarts de configuration

## 1. Le problème à traiter

Les écarts constatés entre dev, stage et production ont trois origines : la **duplication** des fichiers de
configuration, les **modifications appliquées directement** sur un cluster sans retour dans Git, et la
**reconstruction d'artefacts** par environnement. Les trois sont traitées structurellement.

## 2. Principe : une base, des overlays, aucun copier-coller

```
gitops/
├── base/                       # 100 % du commun : Deployment, Service, HPA, PDB, NetworkPolicy…
│   └── kustomization.yaml
└── overlays/
    ├── dev/                    # ce qui DOIT différer, et rien d'autre
    ├── stage/
    └── main/
```

Règle : **un overlay ne contient que des différences justifiées**. Trois catégories seulement sont tolérées :

| Catégorie | Exemples | Contrôle |
|---|---|---|
| Dimensionnement | répliques, CPU/mémoire, bornes HPA | Ratio main/stage documenté |
| Raccordement | URL, noms DNS, endpoints des services tiers | Issu de la même variable d'environnement |
| Sensibilité | référence au secret Vault, niveau de log | Jamais la valeur, seulement la référence |

Tout le reste (image, ports, probes, contexte de sécurité, politiques réseau, annotations) est **imposé par la
base**. Une divergence hors de ces trois catégories est une anomalie détectée par le contrôle de parité en CI.

## 3. Contrôle de parité automatisé

Un job de CI (`scripts/check-env-parity.sh`) rend les overlays, normalise les champs autorisés à différer et
compare les manifestes. Toute différence non déclarée dans `gitops/parity-allowlist.yaml` fait échouer la PR.

```
kustomize build overlays/stage | normalise → A
kustomize build overlays/main    | normalise → B
diff A B  ⟶  différences ⊆ allowlist ?  sinon : échec
```

Effet : la question « pourquoi ça marche en stage et pas en main ? » devient impossible à laisser sans réponse,
car chaque écart est déclaré, revu et daté.

## 4. Détection et correction du drift

Argo CD compare en continu l'état du cluster à l'état Git.

| Environnement | Politique |
|---|---|
| dev, stage | `automated: { prune: true, selfHeal: true }` — correction immédiate |
| production | `selfHeal: true`, `prune: false`, alerte `OutOfSync` en moins de 5 minutes |

Une modification manuelle en production est donc soit annulée automatiquement, soit signalée. Les accès
d'écriture sont retirés ; une procédure de **bris de glace** (compte nominatif temporaire, durée limitée,
journalisation, déclaration d'incident obligatoire) reste disponible pour les cas extrêmes.

## 5. Gestion de la configuration applicative

| Type de donnée | Support | Rechargement |
|---|---|---|
| Paramètre non sensible | ConfigMap générée par Kustomize (avec suffixe de hash) | Redémarrage contrôlé du pod |
| Secret | Vault → External Secrets Operator → Secret k8s | Rotation automatique + `Reloader` |
| Bascule fonctionnelle | Unleash (feature flag) | À chaud, sans déploiement |
| Paramètre métier modifiable par l'exploitant | Table de configuration applicative | À chaud |

Le suffixe de hash des ConfigMaps garantit qu'un changement de configuration provoque un vrai déploiement
versionné, donc **réversible par rollback** comme n'importe quel changement de code.

## 6. Données de stage

Pour que la stage valide réellement la production :
- Rafraîchissement hebdomadaire à partir d'un export de production **anonymisé/pseudonymisé** (conformité RGPD,
  minimisation, procédure validée par le DPO).
- Volumétrie représentative sur les tables critiques, sinon les tests de performance n'ont pas de valeur.
- Topologie identique à la production (mêmes services, même maillage, même ingress), seule l'échelle diffère.

## 7. Infrastructure as Code

Les clusters, réseaux, registres, coffres et DNS sont décrits en Terraform/OpenTofu, avec :
- un module par composant, réutilisé par les trois environnements, paramétré par variables ;
- un état distant chiffré et verrouillé, un état par environnement ;
- `terraform plan` en PR, `apply` après approbation, jamais depuis un poste ;
- `checkov` et `tflint` en contrôle bloquant ;
- une revue trimestrielle des écarts entre le code et la réalité (`plan` à vide doit être vide).
