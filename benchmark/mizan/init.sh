#!/bin/bash -e

# Initiate Mizan by creating machine file.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ../common/get-hosts.sh
source ../common/get-configs.sh

# create machines file
rm -f machines

for ((i = 1; i <= ${machines}; i++)); do
    for ((j = 1; j <= ${MIZAN_WPM}; j++)); do
        echo "${name}${i}" >> machines
    done
done