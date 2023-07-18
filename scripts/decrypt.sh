#!/bin/bash

# Get the directory of the current script
script_dir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1091
source "${script_dir}"/utils.sh

# Exit if no filepath is provided
if [ $# -eq 0 ]; then
	print_red "Error: No encrypted file provided"
	echo "Usage: $0 <encrypted-file>"
	exit 1
fi

file="$1"
output_filepath="${file%%.enc.yaml}.yaml"

# Decrypt the file
sops -d "$file" > "${output_filepath}"

print_green "Decrypted file saved to $output_filepath"
