#!/bin/bash -e

# Simple script to check if workers can be ssh'd to.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./get-hosts.sh
source ./get-dirs.sh

for ((i = 1; i <= ${nodes}; i++)); do
    nc -v -w 1 ${name}${i} -z 22
done
