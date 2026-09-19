# 08 — Tâche 2 : responsabilités, risques, critères de MEP et indicateurs

## 1. Organisation et responsabilités

### 1.1 Rôles

| Rôle | Effectif | Mission dans la transformation |
|---|---|---|
| Chef DevOps (vous) | 1 | Architecture cible, arbitrages, pilotage, relation direction, montée en compétence des équipes |
| Équipe plateforme / SRE | 2–3 | Construction de la chaîne, GitOps, observabilité, secrets, exploitation |
| Équipes de développement | n squads | Tests, qualité, feature flags, migrations, correction des défauts |
| RSSI / sécurité | 1 | Exigences de sécurité, validation des politiques, homologation, revue des exceptions |
| Product Owner / métier | 1 par service | SLO, parcours critiques, recette métier, fenêtres de gel |
| DPO | 1 | Validation de l'anonymisation des données de recette |
| Exploitation / astreinte | — | Runbooks, astreinte, incidents |
| Direction / sponsor | 1 | Mandat, budget, arbitrage fonctionnalités vs fiabilité |

### 1.2 Matrice RACI

R = Réalise · A = Approuve (décide) · C = Consulté · I = Informé

| Activité | Chef DevOps | Plateforme | Dev | RSSI | PO/Métier | Direction |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| Architecture cible CI/CD | **A/R** | C | C | C | I | I |
| Construction des pipelines | A | **R** | C | I | I | I |
| Écriture des tests automatisés | C | C | **R/A** | I | C | I |
| Définition des quality gates | **A** | R | C | C | I | I |
| Politiques de sécurité et admission | C | R | I | **A** | I | I |
| Gestion des secrets (Vault) | A | **R** | C | **A** | I | I |
| GitOps et gestion des environnements | A | **R** | C | I | I | I |
| Définition des SLO | C | R | C | I | **A** | I |
| Approbation d'une MEP de production | C | C | R | I | **A** | I |
| Décision de rollback | **A** | R | C | I | I | I |
| Anonymisation des données de recette | C | R | I | C | I | I |
| Post-mortem | **A/R** | C | C | C | I | I |
| Arbitrage fonctionnalités / fiabilité | C | I | I | C | C | **A** |
| Gel de production | C | I | I | C | R | **A** |

*Le DPO est A sur l'anonymisation des données de recette.*

### 1.3 Rituels

| Rituel | Fréquence | Participants | Objet |
|---|---|---|---|
| Point d'avancement transformation | Hebdo, 30 min | Chef DevOps, plateforme, référents dev | Blocages, avancement des critères de sortie |
| Comité de MEP | Hebdo, 20 min, avant la fenêtre | Chef DevOps, dev, PO | Contenu de la MEP, risques, décision go/no-go |
| Revue des indicateurs | Mensuelle | Chef DevOps, direction | DORA, SLO, sécurité, décisions |
| Revue de sécurité | Mensuelle | Chef DevOps, RSSI | CVE, exceptions actives, incidents |
| Post-mortem | À chaque P1 ou rollback | Parties prenantes | Causes, actions correctives |
| Exercice de rollback | Mensuel | Plateforme + astreinte | Vérifier et chronométrer la procédure |

---

## 2. Risques et mesures de maîtrise

| # | Risque | P | I | Criticité | Mesures de maîtrise | Porteur |
|---|---|:--:|:--:|:--:|---|---|
| R1 | **Absence de tests automatisés existants** : impossible d'activer des gates crédibles en M2 | Élevée | Fort | 🔴 | Priorisation sur les parcours usagers critiques uniquement ; couverture exigée sur le diff, pas sur le legacy ; budget explicite de 20 % de capacité dev en M2 | Chef DevOps |
| R2 | **Résistance au changement** (perte d'accès prod, contrôles bloquants) | Élevée | Fort | 🔴 | Contrôles en avertissement en M1 ; pilote volontaire ; ateliers ; démonstration des gains ; maintien d'une procédure de bris de glace | Chef DevOps |
| R3 | **Migrations de base non réversibles** bloquant le rollback | Moyenne | Fort | 🔴 | Politique expand/contract obligatoire, contrôle CI des migrations destructives, sauvegarde avant migration | Dev + plateforme |
| R4 | **Indisponibilité des équipes** (charge métier, congés, run concurrent) | Élevée | Moyen | 🟠 | Engagement de capacité formalisé dans le mandat ; jalons mensuels ; pilote restreint | Direction |
| R5 | **Faux rollbacks** dus à des SLI mal calibrés | Moyenne | Moyen | 🟠 | Calibrage en recette pendant 2 semaines en mode observation avant activation ; seuils relatifs à une référence glissante | Plateforme |
| R6 | **Fuite de secrets pendant la migration vers Vault** | Moyenne | Fort | 🔴 | Rotation systématique de tout secret migré ; scan de l'historique Git ; révocation des anciens identifiants | RSSI |
| R7 | **Dépendance à une seule personne** sur la chaîne (bus factor) | Moyenne | Fort | 🟠 | Binômage obligatoire, documentation dans le dépôt, runbooks exécutables, revue croisée | Chef DevOps |
| R8 | **Incident majeur pendant la transformation** | Moyenne | Fort | 🟠 | Ancienne procédure de MEP maintenue opérationnelle jusqu'à la fin du M2 ; bascule application par application | Plateforme |
| R9 | **Dérive du périmètre** (demandes annexes : maillage, multi-cluster, refonte) | Élevée | Moyen | 🟠 | Périmètre hors scope écrit et validé ; toute demande nouvelle passe par un arbitrage de direction | Chef DevOps |
| R10 | **Délais d'obtention des ressources** (Vault, licences, runners, environnement) | Moyenne | Moyen | 🟠 | Commandes lancées en semaine 0 ; solution dégradée SOPS+age prévue si Vault tarde | Chef DevOps |
| R11 | **Pipeline lent** décourageant l'usage et incitant au contournement | Moyenne | Moyen | 🟠 | Objectif de retour < 15 min suivi comme un indicateur ; parallélisation ; cache ; tests longs déportés la nuit | Plateforme |
| R12 | **Conformité / homologation** non anticipée bloquant la MEP | Faible | Fort | 🟠 | RSSI associé dès la semaine 0 ; séparation des tâches et journalisation intégrées par conception | RSSI |

**Suivi** : les risques rouges sont revus chaque semaine au point d'avancement, les orange chaque mois.

---

## 3. Critères de mise en production

### 3.1 Critères automatiques (bloquants, vérifiés par le pipeline)

| # | Critère |
|---|---|
| 1 | Tous les tests (unitaires, intégration, contrat, E2E) passent |
| 2 | Couverture du code modifié >= 80 %, quality gate SonarQube au vert |
| 3 | Aucune vulnérabilité `CRITICAL`/`HIGH` non dérogée, aucun secret détecté |
| 4 | Image signée, SBOM et attestation de provenance présents, référencée par digest |
| 5 | Politiques Kyverno respectées |
| 6 | Le digest promu est **exactement** celui validé en recette |
| 7 | Tests de performance dans les seuils (p95, taux d'erreur) |
| 8 | Contrôle de parité d'environnements sans écart non déclaré |
| 9 | Migration de base compatible N-1 |
| 10 | Tests de fumée réussis en recette |

### 3.2 Critères syfFerdinandnels (bloquants, vérifiés par l'humain)

| # | Critère |
|---|---|
| 11 | Recette métier validée par le PO sur les parcours concernés |
| 12 | PR de promotion approuvée par 2 personnes, dont une n'ayant pas écrit le code |
| 13 | MEP dans la fenêtre, hors période de gel |
| 14 | Notes de version générées et communiquées au métier |
| 15 | Budget d'erreur non épuisé (sinon : priorité à la fiabilité) |
| 16 | Procédure de rollback identifiée pour ce changement, et équipe disponible pendant 2 h après la MEP |

### 3.3 Critères d'abandon immédiat (déclenchent le rollback sans réunion)

| # | Déclencheur |
|---|---|
| A1 | Taux de succès du canary < 99,5 % sur une fenêtre de 5 min |
| A2 | p95 de latence > référence + 20 % pendant 5 min |
| A3 | Alerte P1 sur un parcours usager critique |
| A4 | Échec des tests de fumée post-déploiement |
| A5 | Erreur de migration de base de données |

---

## 4. Indicateurs de mesure de l'amélioration

### 4.1 Indicateurs de livraison (DORA)

| Indicateur | Référence estimée | Cible M1 | Cible M2 | Cible M3 | Source |
|---|---|---|---|---|---|
| **Fréquence de déploiement** (prod) | < 1 / mois | 1 / 2 semaines | 1 / semaine | **>= 1 / semaine stable** | Dépôt GitOps |
| **Délai de traversée** (commit → prod) | > 2 semaines | 1 semaine | 3 jours | **< 2 jours** | CI + GitOps |
| **Taux d'échec de changement** | ~50 % (2 rollbacks / ~4 MEP) | < 40 % | < 20 % | **< 10 %** | Incidents / MEP |
| **MTTR** | Plusieurs heures | < 2 h | < 1 h | **< 30 min** | Outil d'incident |

### 4.2 Indicateurs de fiabilité et de sécurité

| Indicateur | Cible M3 |
|---|---|
| Délai de retour arrière mesuré (exercice mensuel) | < 10 min |
| Disponibilité (SLO) | >= 99,9 % |
| Incidents post-déploiement | <= 1 / mois, aucun majeur |
| Secrets présents dans Git | **0** |
| Écarts de configuration non déclarés entre environnements | **0** |
| Images déployées non signées ou non scannées | **0** |
| Âge médian des vulnérabilités `HIGH` ouvertes | < 7 jours |
| Dérives GitOps non corrigées > 24 h | 0 |

### 4.3 Indicateurs de chaîne et d'adoption

| Indicateur | Cible M3 |
|---|---|
| Part des MEP entièrement automatisées | 100 % |
| Durée du pipeline de retour au développeur (étapes 1 à 7) | < 15 min |
| Taux de succès du pipeline sur `main` | > 95 % |
| Taux de tests instables (flaky) | < 2 % |
| Applications migrées sur le nouveau modèle | >= 3 |
| Couverture de tests sur les parcours usagers critiques | 100 % |
| Exceptions de sécurité actives et expirées | 0 expirée |

### 4.4 Restitution

Un tableau de bord Grafana unique, alimenté automatiquement (aucune saisie manuelle), présenté mensuellement
à la direction. Tout indicateur qui demande un travail de collecte manuelle sera abandonné au bout de deux mois :
seule la mesure automatique survit dans la durée.

**Bilan attendu à 3 mois, formulé pour la direction** : passage d'une MEP mensuelle risquée à une MEP
hebdomadaire maîtrisée, division par cinq du taux d'échec de changement, retour arrière garanti sous
10 minutes, et disparition des écarts de configuration entre environnements.
