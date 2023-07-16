#!/usr/bin/env bash

if [ -z "$1" ]
then
  echo "Error: No kind cluster name provided."
  echo "Usage: $0 <cluster-name>"
  exit 1
fi

CLUSTER_NAME="$1"
CONTEXT_NAME="kind-${CLUSTER_NAME}"

# Source the .envrc file to load the GITHUB_USER and GITHUB_REPO environment variables
# shellcheck source=/dev/null
source .envrc

echo ""
if kind get clusters | grep -q "$CLUSTER_NAME"; then
	echo "⏭️  Cluster '$CLUSTER_NAME' already exists. Context will be switched to the current cluster."
else
	echo "👶  Cluster '$CLUSTER_NAME' does not exist. It will be created."
	# Create the cluster
	kind create cluster --name "$CLUSTER_NAME" --config kind/"$CLUSTER_NAME".yaml
fi

# Get cluster info so that the context is defined
echo ""
kubectl cluster-info --context kind-"$CLUSTER_NAME"

# Bootstrap Flux
flux bootstrap github \
--context="${CONTEXT_NAME}" \
--owner="${GITHUB_USER}" \
--repository="${GITHUB_REPO}" \
--branch=main \
--personal \
--path=clusters/"${CLUSTER_NAME}"


# Wait for flux-system namespace conditions to be ready
echo ""
echo "🏗️  Waiting for infra-controllers..."
kubectl -n flux-system wait kustomization/infra-controllers --for=condition=ready --timeout=5m
echo ""
echo "🍦 Waiting for apps..."
kubectl -n flux-system wait kustomization/apps --for=condition=ready --timeout=5m

# Wait for other namespace conditions to be ready
echo ""
echo "🍿 Waiting for the fastapi-example app..."
kubectl -n fastapi-example wait kustomization/fastapi-example --for=condition=ready --timeout=5m
echo ""
echo "🍿 Waiting for the podinfo app..."
kubectl -n podinfo wait helmrelease/podinfo --for=condition=ready --timeout=5m
