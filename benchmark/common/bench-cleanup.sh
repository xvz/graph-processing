#!/bin/bash

# Cleans up rogue stat programs created by bench-init,
# in the event that bench-finish was unable to run.

source "$(dirname "${BASH_SOURCE[0]}")"/get-hosts.sh

for ((i = 0; i <= ${nodes}; i++)); do
    ssh ${name}${i} "kill \$(pgrep sar) & kill \$(pgrep free)" &
done
wait