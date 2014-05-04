#!/bin/bash -e

# Initiate Mizan by creating machine file.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ../common/get-hosts.sh
source ../common/get-configs.sh

# create slaves file
rm -f slaves

for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    for ((j = 1; j <= ${MIZAN_WPM}; j++)); do
        echo "${CLUSTER_NAME}${i}" >> slaves
    done
done