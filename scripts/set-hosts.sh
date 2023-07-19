#!/bin/bash

# Get the directory of the current script
script_dir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1091
source "${script_dir}"/utils.sh

# Array of hostnames that are exposed with an ingress
hostnames=(
	"auth.local"
	"flux.local"
	"fastapi-example.local"
	"grafana.local"
	"podinfo.local"
	"prometheus.local"
)

# Local IP address where the cluster will be listening
ip="127.0.0.1"

# Variable to hold the string of hostnames that will appear in /etc/hosts linked ot the IP
hostnames_str="${hostnames[*]}"

print_yellow "Reading/writing to the /etc/hosts requires sudo privileges!"
# Check if the entry already exists
if grep -q "$ip $hostnames_str"       /etc/hosts; then
	print_blue "The entry $ip $hostnames_str already exists in /etc/hosts"
else
  # Append the entry to /etc/hosts
	echo "$ip       $hostnames_str" | sudo tee -a /etc/hosts
	print_green "Done. $ip $hostnames_str added to /etc/hosts"
fi
