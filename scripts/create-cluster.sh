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

context_name=""
case "$cluster_type" in
	kind)
		print_blue "Creating kind cluster '${cluster_name}'..."
		if kind get clusters | grep -q "${cluster_name}"; then
			print_yellow "Cluster '${cluster_name}' already exists. Context will be switched to the current cluster."
		else
			print_magenta "Cluster '${cluster_name}' does not exist. It will be created."
			# Create the cluster using the configuration file
			kind create cluster --name "${cluster_name}" --config "${script_dir}"/../kind.config.yaml
			print_green "Created kind cluster '${cluster_name}'"
		fi
		context_name="kind-${cluster_name}"
	;;

	k3d)
		print_blue "Creating k3d cluster '${cluster_name}'..."
		if k3d cluster list | grep -q "${cluster_name}"; then
			print_yellow "Cluster '${cluster_name}' already exists. Context will be switched to the current cluster."
		else
			print_magenta "Cluster '${cluster_name}' does not exist. It will be created."
			# Create the cluster using the configuration file
			k3d cluster create --config "${script_dir}"/../k3d.config.yaml "${cluster_name}"
			print_green "Created k3d cluster '${cluster_name}'"
		fi
		context_name="k3d-${cluster_name}"
	;;

	*)
		# Unsupported cluster types
		print_red "Error: Unsupported cluster type. Only 'kind' and 'k3d' are supported."
		exit 1
	;;
esac

# Get cluster info so that the context is defined
echo ""
kubectl cluster-info --context "${context_name}"
