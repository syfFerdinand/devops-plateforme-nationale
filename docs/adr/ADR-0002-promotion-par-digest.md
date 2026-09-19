# ADR-0002 — Promouvoir un artefact unique par digest, sans reconstruction

- **Statut** : accepté
- **Date** : semaine 1

## Contexte
Des écarts de configuration existent entre dev, stage et production. Une reconstruction d'image par
environnement rend impossible la garantie que ce qui a été validé est ce qui est déployé.

## Décision
Une seule construction par commit. L'artefact est référencé par son digest `sha256` tout au long de la chaîne.
La promotion consiste uniquement à modifier la référence de digest dans l'overlay de l'environnement cible.
Les tags mutables (`latest`, `main`) sont interdits en stage et en production, règle appliquée par Kyverno.

## Conséquences
- **Positives** : la stage valide réellement ce qui ira en production ; la traçabilité est exacte ; le
  rollback consiste à remettre le digest précédent.
- **Négatives** : les digests sont peu lisibles par un humain (compensés par des annotations portant la version
  sémantique et le commit) ; toute configuration spécifique à un environnement doit être externalisée de l'image.
