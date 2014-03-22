#!/bin/bash

# Restarts Hadoop and kills any lingering Java processes.
# This is indiscriminate---it will kill ALL Java processes.
#
# NOTE: To programmatically detect when Hadoop is up, use
# "hadoop dfsadmin -safemode wait"

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-hosts.sh

stop-all.sh

# do a kill on the master separately---this is useful when testing on a single machine
kill -9 $(pgrep java)

for ((i = 1; i <= ${nodes}; i++)); do
    ssh ${name}${i} "kill -9 \$(pgrep java)" &
done
wait

start-all.sh