#!/bin/bash

# Simple script to check if worker machines can be ssh'd to.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./get-hosts.sh
source ./get-dirs.sh

for ((i = 1; i <= ${machines}; i++)); do
    nc -v -w 1 ${name}${i} -z 22
done
