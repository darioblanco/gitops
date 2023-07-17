.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.PHONY: clean \
		e2e-crossplane e2e-production e2e-staging \
		gitops-crossplane gitops-production gitops-staging \
		format flux-ui help hosts init validate

clean: init ## clean up all locally created resources
	kind delete cluster --name crossplane
	kind delete cluster --name production
	kind delete cluster --name staging

e2e-crossplane: init ## create a local crossplane cluster with kind and sync with flux without gitops
	./scripts/create-cluster.sh kind crossplane
	./scripts/provision-cluster.sh crossplane kind-crossplane
	kubectl -n flux-system wait kustomization/crossplane-providers --for=condition=ready --timeout=5m
	kubectl -n flux-system wait kustomization/crossplane-resources --for=condition=ready --timeout=5m

e2e-production: init ## create a local production cluster with kind and sync with flux without gitops
	./scripts/create-cluster.sh kind production
	./scripts/provision-cluster.sh production kind-production
	kubectl -n flux-system wait kustomization/infra-controllers --for=condition=ready --timeout=5m
	kubectl -n flux-system wait kustomization/apps --for=condition=ready --timeout=5m
	kubectl -n fastapi-example wait kustomization/fastapi-example --for=condition=ready --timeout=5m
	kubectl -n podinfo wait helmrelease/podinfo --for=condition=ready --timeout=5m

e2e-staging: init ## create a local staging cluster with kind and sync with flux without gitops
	./scripts/create-cluster.sh kind staging
	./scripts/provision-cluster.sh staging kind-staging
	kubectl -n flux-system wait kustomization/infra-controllers --for=condition=ready --timeout=5m
	kubectl -n flux-system wait kustomization/apps --for=condition=ready --timeout=5m
	kubectl -n fastapi-example wait kustomization/fastapi-example --for=condition=ready --timeout=5m
	kubectl -n podinfo wait helmrelease/podinfo --for=condition=ready --timeout=5m

gitops-crossplane: init ## create a local crossplane cluster with kind and sync with flux via gitops
	./scripts/create-cluster.sh kind crossplane
	./scripts/provision-cluster.sh crossplane kind-crossplane --gitops
	kubectl -n flux-system wait kustomization/crossplane-providers --for=condition=ready --timeout=5m
	kubectl -n flux-system wait kustomization/crossplane-resources --for=condition=ready --timeout=5m

gitops-production: init ## create a local production cluster with kind and sync with flux via gitops
	./scripts/create-cluster.sh kind production
	./scripts/provision-cluster.sh production kind-production --gitops
	kubectl -n flux-system wait kustomization/infra-controllers --for=condition=ready --timeout=5m
	kubectl -n flux-system wait kustomization/apps --for=condition=ready --timeout=5m
	kubectl -n fastapi-example wait kustomization/fastapi-example --for=condition=ready --timeout=5m
	kubectl -n podinfo wait helmrelease/podinfo --for=condition=ready --timeout=5m

gitops-staging: init ## create a local staging cluster with kind and sync with flux via gitops
	./scripts/create-cluster.sh kind staging
	./scripts/provision-cluster.sh staging kind-staging --gitops
	kubectl -n flux-system wait kustomization/infra-controllers --for=condition=ready --timeout=5m
	kubectl -n flux-system wait kustomization/apps --for=condition=ready --timeout=5m
	kubectl -n fastapi-example wait kustomization/fastapi-example --for=condition=ready --timeout=5m
	kubectl -n podinfo wait helmrelease/podinfo --for=condition=ready --timeout=5m

format: init ## format yaml and json files
	prettier --write "**/*.{json,yaml,yml}"

flux-ui: init ## port-forward to the current kubernetes cluster so flux UI can be accessed in http://localhost:9001
	kubectl -n flux-system port-forward svc/weave-gitops 9001:9001

help: ## list available commands
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

hosts: ## Define local hostnames that will point to the cluster IP in relation to the ingresses
	./scripts/set-hosts.sh

init: ## verify that all the required commands are already installed
	@if [ -z "$$CI" ]; then \
		function cmd { \
			if ! command -v "$$1" &>/dev/null ; then \
				echo "error: missing required command in PATH: $$1" >&2 ;\
				return 1 ;\
			fi \
		} ;\
		cmd age-keygen ;\
		cmd flux ;\
		cmd kind ;\
		cmd kubeconform ;\
		cmd kubectl ;\
		cmd prettier ;\
		cmd sops ;\
		cp .githooks/* .git/hooks/ ;\
		git config diff.sopsdiffer.textconv "sops -d" ;\
	fi

validate: init # validate the flux custom resources and kustomize overlays using kubeconform
	./scripts/validate.sh
