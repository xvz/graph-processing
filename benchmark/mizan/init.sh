#!/bin/bash -e

# Initiate Mizan by creating machine file.

read -p "Enter to continue..." none

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-hosts.sh

# create machines file
rm -f machines

for ((i = 1; i <= ${nodes}; i++)); do
    echo "${name}${i}" >> machines
done