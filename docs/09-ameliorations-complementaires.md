# 09 — Améliorations complémentaires du système (au-delà de la demande initiale)

Ces chantiers ne sont pas nécessaires pour atteindre l'objectif de MEP hebdomadaire, mais ils consolident la
plateforme dans la durée. Ils constituent la feuille de route M4 à M9.

## 1. Platform engineering et parcours balisés

Le principal risque à 6 mois est que la chaîne devienne complexe et que seules deux personnes sachent s'en servir.
Réponse : traiter la plateforme comme un produit destiné aux équipes de développement.

- **Template de service** (`cookiecutter` / Backstage) : un nouveau service est créé avec son dépôt, sa CI,
  ses manifestes, ses tableaux de bord et ses alertes préconfigurés, en moins de 30 minutes.
- **Catalogue de services** (Backstage) : propriétaire, SLO, dépendances, runbooks, état de santé en un seul endroit.
- **Objectif mesurable** : délai de mise à disposition d'un nouveau service, de plusieurs semaines à moins d'une journée.

## 2. Déploiement à la demande

Une fois le taux d'échec de changement stabilisé sous 10 % pendant 4 semaines, suppression de la fenêtre de MEP
et passage au déploiement à la demande, plusieurs fois par jour. Prérequis : canary automatique éprouvé,
feature flags généralisés, astreinte outillée. C'est la suite naturelle du plan, pas un objectif des 3 premiers mois.

## 3. Résilience et continuité d'activité

| Chantier | Contenu | Indicateur |
|---|---|---|
| PRA / PCA | Restauration complète depuis Git + sauvegardes (Velero), site de secours | RTO < 4 h, RPO < 15 min |
| Test de restauration | Exercice trimestriel de reconstruction complète d'un environnement depuis zéro | Procès-verbal daté |
| Multi-zone | Répartition des charges de travail sur plusieurs zones de disponibilité | Perte d'une zone sans interruption |
| Dégradation maîtrisée | Coupe-circuits, limitation de débit, mode dégradé par service | Comportement vérifié en test |
| Chaos engineering | Injection de pannes contrôlées en recette puis en production (Litmus) | 1 expérience / mois |

Pour un service public, la capacité à **reconstruire la plateforme à partir de Git et des sauvegardes** est la
garantie la plus solide. Elle se teste, elle ne se suppose pas.

## 4. Maîtrise des coûts (FinOps)

- Étiquetage obligatoire des ressources par service et par environnement, imposé par politique d'admission.
- Suivi du coût par namespace (Kubecost / OpenCost), restitution mensuelle aux équipes.
- Ajustement automatique des demandes de ressources (VPA en recommandation) : les ressources sur-provisionnées
  sont la source la plus fréquente de gaspillage sur Kubernetes.
- Extinction automatique des environnements hors production la nuit et le week-end.
- Nettoyage automatique des images et environnements éphémères.

## 5. Accessibilité et qualité de service public

- Contrôle RGAA automatisé dans le pipeline (axe-core), bloquant sur les violations critiques.
- Budget de performance côté navigateur (Lighthouse CI) : un service national doit rester utilisable sur
  connexion lente et matériel ancien.
- Suivi de l'expérience réelle des usagers (RUM) en complément des métriques serveur.

## 6. Sécurité avancée

- Progression vers **SLSA niveau 3** : build isolé, provenance non falsifiable.
- Politique de gestion des dépendances : interdiction des dépendances non maintenues, contrôle des licences.
- Tests d'intrusion annuels, programme de divulgation coordonnée de vulnérabilités.
- Chiffrement des données au repos et en transit, rotation des clés, cloisonnement réseau strict par namespace.
- Revue trimestrielle des droits (RBAC, Vault, forge Git) avec retrait automatique des accès inactifs.

## 7. Qualité de la donnée et migrations

- Contrats de données entre services, validation de schéma au moment de la publication.
- Outillage de migration versionné (Flyway / Liquibase) avec vérification automatique de la réversibilité.
- Sauvegardes testées par restauration réelle, pas seulement vérifiées comme présentes.

## 8. Culture et pérennité

- Post-mortems publiés et consultables, sans recherche de faute.
- Rotation de l'astreinte incluant les développeurs : celui qui écrit le code en assume l'exploitation.
- Temps dédié à la réduction de la dette technique (20 % de la capacité), protégé par la politique de budget d'erreur.
- Documentation vivante dans le dépôt, révisée à chaque changement, jamais dans un outil séparé.
