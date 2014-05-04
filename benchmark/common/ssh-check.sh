#!/bin/bash

# Simple script to check if worker machines can be ssh'd to.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./get-hosts.sh
source ./get-dirs.sh

for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    nc -v -w 1 ${CLUSTER_NAME}${i} -z 22
done
