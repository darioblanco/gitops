#!/bin/bash

# Get the directory of the current script
script_dir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1091
source "${script_dir}"/utils.sh

# Exit if no filepath is provided
if [ $# -eq 0 ]; then
	print_red "Error: No file provided"
	echo "Usage: $0 <file>"
	exit 1
fi

# Get the input file path
input_filepath="$1"

# Get the filename without the extension
filename=$(basename -- "${input_filepath}")
name="${filename%.*}"

# Get the directory path
dirpath=$(dirname -- "${input_filepath}")

# Construct the output file path
output_filepath="${dirpath}/${name}.enc.yaml"

# Encrypt the file into a new file with the `.enc.yaml` extension
sops -e "${input_filepath}" > "${output_filepath}"

# Format the sops generated file to follow our file conventions
prettier --write "${output_filepath}"

print_green "Encrypted file saved to ${output_filepath}"
