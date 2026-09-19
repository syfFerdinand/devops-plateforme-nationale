#!/usr/bin/env bash
# Toute dérogation de sécurité porte une date d'expiration.
# Une dérogation expirée refait échouer le pipeline (docs/02 §2).
set -euo pipefail
AUJOURDHUI=$(date +%Y-%m-%d)
CODE=0

for FICHIER in .trivyignore .semgrepignore; do
  [[ -f "$FICHIER" ]] || continue
  while IFS= read -r LIGNE; do
    [[ "$LIGNE" =~ exp:([0-9]{4}-[0-9]{2}-[0-9]{2}) ]] || continue
    EXPIRATION="${BASH_REMATCH[1]}"
    if [[ "$EXPIRATION" < "$AUJOURDHUI" ]]; then
      echo "❌ Dérogation expirée le $EXPIRATION dans $FICHIER : $LIGNE"
      CODE=1
    fi
  done < "$FICHIER"
done

[[ $CODE -eq 0 ]] && echo "✅ Aucune dérogation de sécurité expirée."
exit $CODE
