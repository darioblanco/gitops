#!/usr/bin/env bash

# Exit if one of the scripts fail
set -e

# Get the directory of the current script
script_dir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1091
source "${script_dir}"/utils.sh

# Initialize flags
gitops_flag=false

# Parse flags
while (( "$#" )); do
  case "$1" in
    --gitops)
      gitops_flag=true
      shift
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Set positional arguments in their proper place
eval set -- "$PARAMS"

# Check that cluster_name is provided
if [ -z "$1" ]
then
	print_red "Error: No kubernetes cluster name provided."
	echo "Usage: $0 [--gitops] <cluster_name> <context-name>"
	exit 1
fi

# Check that context_name is provided
if [ -z "$2" ]
then
	print_red "Error: No kubernetes context name provided."
	echo "Usage: $0 [--gitops] <cluster_name> <context-name>"
	exit 1
fi

cluster_name="$1"
context_name="$2"
private_key_path="./clusters/${cluster_name}/sops.agekey"

# Source the .envrc file to load the GITHUB_USER and GITHUB_REPO environment variables
# shellcheck source=/dev/null
source .envrc

if [ "$gitops_flag" = true ] ; then
	# Provision flux the "gitops" way (https://fluxcd.io/flux/cmd/flux_bootstrap/)
	echo ""
	print_blue "Provisioning flux with gitops..."
	flux bootstrap github \
	--branch=main \
	--components-extra=image-reflector-controller,image-automation-controller \
	--context="${context_name}" \
	--owner="${GITHUB_OWNER}" \
	--path=clusters/"${cluster_name}" \
	--personal \
	--read-write-key \
	--repository="${GITHUB_REPO}"
else
	echo ""
	print_blue "Provisioning flux without gitops..."
	flux install \
	--components-extra=image-reflector-controller,image-automation-controller \
	--context="${context_name}"
	flux create source git flux-system \
	--context="${context_name}" \
	--url=https://github.com/"${GITHUB_OWNER}"/"${GITHUB_REPO}" \
	--branch=main \
	--ignore-paths=clusters/"${cluster_name}"/flux-system/
	flux create kustomization flux-system \
	--context="${context_name}" \
	--source=flux-system \
	--path=./clusters/"${cluster_name}"
fi
print_green "Cluster provisioned successfully"

if [ ! -f "$private_key_path" ]; then
	echo ""
	print_yellow "The private key does not exist in ${private_key_path}."

	read -r -p "👉 Do you want to generate a new one? You will later need to update the to update the ./.sops.yaml file with its public key for ${cluster_name} [y/n]: " generate_age_key
	if [[ $generate_age_key =~ ^[yY] ]]; then
		age-keygen -o "${private_key_path}"
		print_green "New age key generated in ${private_key_path}, do not forget to update the ./.sops.yaml file with the public key for ${cluster_name}"
	else
		print_yellow "Skipped cluster provision, a private key needs to be provided. You might want to set ${private_key_path} with an age key from a password manager or any other external source. "
		exit_gracefully
	fi
fi

# Provision the key that will be used to decrypt sops secrets
echo ""
print_blue "🔑 Creating private sops-age key for global secret management..."

if kubectl get secret sops-age --context="${context_name}" --namespace=flux-system > /dev/null 2>&1; then
	print_yellow "Secret 'sops-age' already exists. Skipping creation."
else
kubectl create secret generic sops-age \
	--context="${context_name}" \
	--namespace=flux-system \
	--from-file=./clusters/"${cluster_name}"/sops.agekey
	print_green "Secret 'sops-age' created."
fi
echo ""
