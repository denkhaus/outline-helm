# Outline Helm Chart Makefile
# ================================

# Variables
CHART_DIR := charts/outline
CHART_NAME := outline
NAMESPACE := outline
RELEASE_NAME := outline-test
HELM_REPO_NAME := outline-helm
HELM_REPO_URL := https://denkhaus.github.io/outline-helm

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Outline Helm Chart Development$(NC)"
	@echo "==============================="
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make test          # Run all tests"
	@echo "  make install       # Install chart locally"
	@echo "  make upgrade       # Upgrade existing installation"
	@echo "  make clean         # Clean up test installations"

# Development targets
.PHONY: deps
deps: ## Update Helm dependencies
	@echo "$(YELLOW)Updating Helm dependencies...$(NC)"
	cd $(CHART_DIR) && helm dependency update
	@echo "$(GREEN)Dependencies updated successfully!$(NC)"

.PHONY: lint
lint: deps ## Lint the Helm chart
	@echo "$(YELLOW)Linting Helm chart...$(NC)"
	cd $(CHART_DIR) && helm lint .
	@echo "$(GREEN)Linting completed!$(NC)"

.PHONY: template
template: deps ## Generate and validate templates
	@echo "$(YELLOW)Validating Helm templates...$(NC)"
	cd $(CHART_DIR) && helm template $(RELEASE_NAME) . --dry-run > /dev/null
	@echo "$(GREEN)Template validation passed!$(NC)"

.PHONY: unittest
unittest: ## Run unit tests
	@echo "$(YELLOW)Running unit tests...$(NC)"
	@if ! helm plugin list | grep -q unittest; then \
		echo "$(YELLOW)Installing helm unittest plugin...$(NC)"; \
		helm plugin install https://github.com/helm-unittest/helm-unittest; \
	fi
	cd $(CHART_DIR) && helm unittest .
	@echo "$(GREEN)Unit tests completed!$(NC)"

.PHONY: test
test: lint template unittest ## Run all tests (lint, template validation, unit tests)
	@echo "$(YELLOW)Running comprehensive test suite...$(NC)"
	cd $(CHART_DIR) && chmod +x test.sh && ./test.sh
	@echo "$(GREEN)All tests passed!$(NC)"

.PHONY: test-configs
test-configs: ## Test different configuration scenarios
	@echo "$(YELLOW)Testing different configurations...$(NC)"
	@echo "Testing with ingress disabled..."
	cd $(CHART_DIR) && helm template $(RELEASE_NAME) . --set ingress.enabled=false --dry-run > /dev/null
	@echo "Testing with external dependencies disabled..."
	cd $(CHART_DIR) && helm template $(RELEASE_NAME) . \
		--set postgresql.enabled=false \
		--set redis.enabled=false \
		--set minio.enabled=false \
		--dry-run > /dev/null
	@echo "Testing with auth providers..."
	cd $(CHART_DIR) && helm template $(RELEASE_NAME) . \
		--set env.SLACK_CLIENT_ID=test \
		--set env.GOOGLE_CLIENT_ID=test \
		--dry-run > /dev/null
	@echo "$(GREEN)Configuration tests passed!$(NC)"

# Installation targets
.PHONY: create-namespace
create-namespace: ## Create the outline namespace
	@echo "$(YELLOW)Creating namespace $(NAMESPACE)...$(NC)"
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "$(GREEN)Namespace ready!$(NC)"

.PHONY: create-secrets
create-secrets: create-namespace ## Create required secrets for testing
	@echo "$(YELLOW)Creating test secrets...$(NC)"
	kubectl create secret generic outline-secrets \
		--from-literal=SECRET_KEY="$$(openssl rand -hex 32)" \
		--from-literal=UTILS_SECRET="$$(openssl rand -hex 32)" \
		--from-literal=SLACK_CLIENT_SECRET="test-slack-secret" \
		--from-literal=SMTP_PASSWORD="test-smtp-password" \
		--namespace=$(NAMESPACE) \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo "$(GREEN)Test secrets created!$(NC)"

.PHONY: install
install: deps create-secrets ## Install the chart locally
	@echo "$(YELLOW)Installing Helm chart...$(NC)"
	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait \
		--timeout 10m
	@echo "$(GREEN)Chart installed successfully!$(NC)"
	@echo "$(BLUE)Access your installation:$(NC)"
	@echo "  kubectl get pods -n $(NAMESPACE)"
	@echo "  kubectl get svc -n $(NAMESPACE)"

.PHONY: install-minimal
install-minimal: deps create-secrets ## Install with minimal configuration (no ingress, external deps)
	@echo "$(YELLOW)Installing minimal configuration...$(NC)"
	helm upgrade --install $(RELEASE_NAME)-minimal $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set ingress.enabled=false \
		--set postgresql.enabled=false \
		--set redis.enabled=false \
		--set minio.enabled=false \
		--wait \
		--timeout 5m
	@echo "$(GREEN)Minimal installation completed!$(NC)"

.PHONY: deploy
deploy: deps ## Deploy to production (requires existing secrets and values file)
	@echo "$(YELLOW)Deploying to production...$(NC)"
	@if [ ! -f "production-values.yaml" ]; then \
		echo "$(RED)Error: production-values.yaml not found!$(NC)"; \
		echo "$(YELLOW)Create a production-values.yaml file with your configuration.$(NC)"; \
		echo "$(YELLOW)Example: cp charts/outline/examples/README.md production-values.yaml$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Validating production configuration...$(NC)"
	helm template $(RELEASE_NAME) $(CHART_DIR) -f production-values.yaml --dry-run > /dev/null
	@echo "$(YELLOW)Deploying with production values...$(NC)"
	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--values production-values.yaml \
		--wait \
		--timeout 15m \
		--atomic
	@echo "$(GREEN)Production deployment completed!$(NC)"
	@echo "$(BLUE)Deployment status:$(NC)"
	@helm status $(RELEASE_NAME) --namespace $(NAMESPACE)

.PHONY: deploy-staging
deploy-staging: deps ## Deploy to staging environment
	@echo "$(YELLOW)Deploying to staging...$(NC)"
	@if [ ! -f "staging-values.yaml" ]; then \
		echo "$(YELLOW)staging-values.yaml not found, using default values...$(NC)"; \
	fi
	helm upgrade --install $(RELEASE_NAME)-staging $(CHART_DIR) \
		--namespace $(NAMESPACE)-staging \
		--create-namespace \
		$(if $(wildcard staging-values.yaml),--values staging-values.yaml,) \
		--set ingress.host=staging-outline.yourdomain.tld \
		--wait \
		--timeout 10m \
		--atomic
	@echo "$(GREEN)Staging deployment completed!$(NC)"

.PHONY: upgrade
upgrade: deps ## Upgrade existing installation
	@echo "$(YELLOW)Upgrading Helm chart...$(NC)"
	helm upgrade $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) \
		--wait \
		--timeout 10m
	@echo "$(GREEN)Chart upgraded successfully!$(NC)"

.PHONY: uninstall
uninstall: ## Uninstall the chart
	@echo "$(YELLOW)Uninstalling Helm chart...$(NC)"
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) || true
	helm uninstall $(RELEASE_NAME)-minimal --namespace $(NAMESPACE) || true
	helm uninstall $(RELEASE_NAME)-staging --namespace $(NAMESPACE)-staging || true
	@echo "$(GREEN)Chart uninstalled!$(NC)"

.PHONY: clean
clean: uninstall ## Clean up test installations and secrets
	@echo "$(YELLOW)Cleaning up test resources...$(NC)"
	kubectl delete secret outline-secrets --namespace $(NAMESPACE) --ignore-not-found
	kubectl delete namespace $(NAMESPACE) --ignore-not-found
	@echo "$(GREEN)Cleanup completed!$(NC)"

# Repository management
.PHONY: package
package: deps lint ## Package the chart
	@echo "$(YELLOW)Packaging Helm chart...$(NC)"
	helm package $(CHART_DIR) --destination ./dist
	@echo "$(GREEN)Chart packaged successfully!$(NC)"

.PHONY: repo-add
repo-add: ## Add the Helm repository
	@echo "$(YELLOW)Adding Helm repository...$(NC)"
	helm repo add $(HELM_REPO_NAME) $(HELM_REPO_URL)
	helm repo update
	@echo "$(GREEN)Repository added!$(NC)"

.PHONY: repo-install
repo-install: repo-add create-secrets ## Install from the Helm repository
	@echo "$(YELLOW)Installing from repository...$(NC)"
	helm upgrade --install $(RELEASE_NAME) $(HELM_REPO_NAME)/$(CHART_NAME) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait \
		--timeout 10m
	@echo "$(GREEN)Installed from repository!$(NC)"

# Development utilities
.PHONY: debug
debug: ## Show debug information about the chart
	@echo "$(YELLOW)Chart debug information:$(NC)"
	@echo "Chart directory: $(CHART_DIR)"
	@echo "Chart name: $(CHART_NAME)"
	@echo "Namespace: $(NAMESPACE)"
	@echo "Release name: $(RELEASE_NAME)"
	@echo ""
	@echo "$(YELLOW)Chart metadata:$(NC)"
	cd $(CHART_DIR) && helm show chart .
	@echo ""
	@echo "$(YELLOW)Dependencies:$(NC)"
	cd $(CHART_DIR) && helm dependency list

.PHONY: values
values: ## Show default values
	@echo "$(YELLOW)Default chart values:$(NC)"
	cd $(CHART_DIR) && helm show values .

.PHONY: template-debug
template-debug: ## Generate templates with debug output
	@echo "$(YELLOW)Generating templates with debug...$(NC)"
	cd $(CHART_DIR) && helm template $(RELEASE_NAME) . --debug

.PHONY: status
status: ## Show status of installed chart
	@echo "$(YELLOW)Chart status:$(NC)"
	helm status $(RELEASE_NAME) --namespace $(NAMESPACE) || echo "Chart not installed"
	@echo ""
	@echo "$(YELLOW)Kubernetes resources:$(NC)"
	kubectl get all -n $(NAMESPACE) || echo "Namespace not found"

# CI/CD targets
.PHONY: ci-test
ci-test: deps lint template unittest test-configs ## Run all CI tests
	@echo "$(GREEN)All CI tests passed!$(NC)"

.PHONY: security-check
security-check: ## Check for security issues
	@echo "$(YELLOW)Running security checks...$(NC)"
	@echo "Checking that core secrets come from Kubernetes secrets..."
	cd $(CHART_DIR) && helm template $(RELEASE_NAME) . --dry-run | grep -q "secretKeyRef:" || (echo "$(RED)No secret references found!$(NC)" && exit 1)
	@echo "Checking that SECRET_KEY comes from secret..."
	cd $(CHART_DIR) && helm template $(RELEASE_NAME) . --dry-run | grep -A 3 "name: SECRET_KEY" | grep -q "secretKeyRef" || (echo "$(RED)SECRET_KEY not from secret!$(NC)" && exit 1)
	@echo "Checking that UTILS_SECRET comes from secret..."
	cd $(CHART_DIR) && helm template $(RELEASE_NAME) . --dry-run | grep -A 3 "name: UTILS_SECRET" | grep -q "secretKeyRef" || (echo "$(RED)UTILS_SECRET not from secret!$(NC)" && exit 1)
	@echo "$(GREEN)Security check passed!$(NC)"

.PHONY: version-check
version-check: ## Check chart and app versions
	@echo "$(YELLOW)Version information:$(NC)"
	cd $(CHART_DIR) && grep "version:" Chart.yaml
	cd $(CHART_DIR) && grep "appVersion:" Chart.yaml
	cd $(CHART_DIR) && grep "tag:" values.yaml

# Documentation
.PHONY: docs
docs: ## Generate documentation
	@echo "$(YELLOW)Chart documentation:$(NC)"
	@echo "Main README: README.md"
	@echo "Chart README: $(CHART_DIR)/README.md"
	@echo "Examples: $(CHART_DIR)/examples/"
	@echo "Testing guide: $(CHART_DIR)/TESTING.md"
	@echo "Migration guide: $(CHART_DIR)/MIGRATION-v0.85.md"
	@echo "Changelog: $(CHART_DIR)/CHANGELOG.md"

# Quick development workflow
.PHONY: dev
dev: deps lint template ## Quick development check (deps + lint + template)
	@echo "$(GREEN)Development check completed!$(NC)"

.PHONY: full-test
full-test: deps lint template unittest test-configs security-check ## Full test suite including security
	@echo "$(GREEN)Full test suite completed!$(NC)"