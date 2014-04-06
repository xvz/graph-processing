#!/bin/bash -e

# Initiate GraphLab by creating machine file.
# The contents actually correspond to physical machines.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ../common/get-hosts.sh

# create machines file
rm -f machines

for ((i = 1; i <= ${machines}; i++)); do
    echo "${name}${i}" >> machines
done