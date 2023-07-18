#!/usr/bin/env bash

# Exit if one of the scripts fail
set -e

# Get the directory of the current script
script_dir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1091
source "${script_dir}"/utils.sh

if [ -z "$1" ]
then
  print_red "Error: No cluster type provided."
  echo "Usage: $0 <cluster-type> <cluster-name>"
  exit 1
fi

if [ -z "$2" ]
then
  print_red "Error: No cluster name provided."
  echo "Usage: $0 <cluster-type> <cluster-name>"
  exit 1
fi

cluster_type="$1"
cluster_name="$2"

# Check if cluster type is "kind" (the only supported type at the moment)
if [ "$cluster_type" != "kind" ]
then
  print_red "Error: Unsupported cluster type. Only 'kind' is supported."
  exit 1
fi

echo ""
if kind get clusters | grep -q "${cluster_name}"; then
	print_yellow "Cluster '${cluster_name}' already exists. Context will be switched to the current cluster."
else
	print_magenta "Cluster '${cluster_name}' does not exist. It will be created."
	# Create the cluster
	kind create cluster --name "${cluster_name}" --config "${script_dir}"/../kind.medium.yaml
	print_green "Created kind cluster '${cluster_name}'"
fi

# Get cluster info so that the context is defined
echo ""
kubectl cluster-info --context kind-"${cluster_name}"
