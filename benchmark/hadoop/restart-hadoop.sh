#!/bin/bash

# Restarts Hadoop and kills any lingering Java processes.
# This is indiscriminate---it will kill ALL Java processes.
#
# NOTE: To programmatically detect when Hadoop is up, use
# "hadoop dfsadmin -safemode wait" or pass in "1" as arg.
#
# usage: ./restart-hadoop.sh [wait?]
#
# wait: 0 for no wait, 1 to wait for Hadoop to start

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-hosts.sh

stop-all.sh

# do a kill on the master separately---this is useful when testing on a single machine
kill -9 $(pgrep java)

for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    ssh ${CLUSTER_NAME}${i} "kill -9 \$(pgrep java)" &
done
wait

start-all.sh

if [[ $# -eq 1 && $1 -eq 1 ]]; then
    # wait until Hadoop is up
    hadoop dfsadmin -safemode wait
fi