.DEFAULT_GOAL := aide
SHELL := /bin/bash

aide: ## Afficher cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS=":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

valider: manifestes politiques parite ## Tous les contrôles locaux avant de pousser

manifestes: ## Valider les manifestes contre le schéma Kubernetes
	@for env in dev recette prod; do \
	  echo "→ $$env"; \
	  kustomize build gitops/overlays/$$env | kubeconform -strict -summary -; \
	done

politiques: ## Vérifier les manifestes de production contre les politiques
	@kustomize build gitops/overlays/prod | conftest test --policy policies/ -

parite: ## Contrôler la parité recette / production
	@./scripts/check-env-parity.sh recette prod

exceptions: ## Détecter les dérogations de sécurité expirées
	@./scripts/check-exceptions.sh

rendre: ## Afficher les manifestes rendus (ENV=prod make rendre)
	@kustomize build gitops/overlays/$${ENV:-dev}

rollback: ## Rollback assisté (SERVICE=app-usagers make rollback)
	@./scripts/rollback.sh $${SERVICE:?SERVICE requis} $${NS:-prod}

.PHONY: aide valider manifestes politiques parite exceptions rendre rollback
