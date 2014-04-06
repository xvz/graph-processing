#!/bin/bash -e

# Initiate Mizan by creating machine file.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ../common/get-hosts.sh

# create machines file
rm -f machines

MIZAN_CPUS=2

for ((i = 1; i <= ${nodes}; i++)); do
    for ((j = 1; j <= ${MIZAN_CPUS}; j++)); do
        echo "${name}${i}" >> machines
    done
done