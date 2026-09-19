.DEFAULT_GOAL := aide
SHELL := /bin/bash

aide: ## Afficher cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS=":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

valider: manifestes politiques parite regles alertes dashboards ## Tous les contrôles locaux avant de pousser

manifestes: ## Valider les manifestes contre le schéma Kubernetes
	@for env in dev recette prod; do \
	  echo "→ $$env"; \
	  kustomize build gitops/overlays/$$env | kubeconform -strict -summary -; \
	done

politiques: ## Vérifier les manifestes de production contre les politiques
	@kustomize build gitops/overlays/prod | conftest test --policy policies/ -

parite: ## Contrôler la parité recette / production
	@./scripts/check-env-parity.sh recette prod

regles: ## Valider la syntaxe des règles Prometheus
	@mkdir -p /tmp/regles
	@for f in gitops/base/slo-rules.yaml gitops/observabilite/prometheus-rules-*.yaml; do \
	  yq '.spec' $$f > /tmp/regles/$$(basename $$f); done
	@promtool check rules /tmp/regles/*.yaml

alertes: ## Exécuter les tests unitaires des alertes
	@promtool test rules tests/prometheus/*-test.yaml

dashboards: ## Vérifier la validité des tableaux de bord Grafana
	@for f in gitops/observabilite/grafana-dashboards/*.json; do \
	  jq -e '.uid and .title and (.panels | length > 0)' $$f > /dev/null && echo "  ✅ $$(basename $$f)"; done

exceptions: ## Détecter les dérogations de sécurité expirées
	@./scripts/check-exceptions.sh

rendre: ## Afficher les manifestes rendus (ENV=prod make rendre)
	@kustomize build gitops/overlays/$${ENV:-dev}

rollback: ## Rollback assisté (SERVICE=app-usagers make rollback)
	@./scripts/rollback.sh $${SERVICE:?SERVICE requis} $${NS:-prod}

.PHONY: aide valider manifestes politiques parite regles alertes dashboards exceptions rendre rollback
