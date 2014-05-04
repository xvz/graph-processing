#!/bin/bash

# Cleans up rogue stat programs created by bench-init,
# in the event that bench-finish was unable to run.
#
# Alternatively, one can run bench-finish by passing in
# the correct log name prefix to clean things up and get
# the worker machines' (incomplete) logs.

source "$(dirname "${BASH_SOURCE[0]}")"/get-hosts.sh

for ((i = 0; i <= ${NUM_MACHINES}; i++)); do
    # special case for master, to make it work for local testing too
    if [ $i -eq  0 ]; then
        name=${HOSTNAME}
    else
        name=${CLUSTER_NAME}${i}
    fi

    ssh ${name} "kill \$(pgrep sar) & kill \$(pgrep free)" &
done
wait