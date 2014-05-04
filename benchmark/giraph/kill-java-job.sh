#!/bin/bash

# Kill all Java instances corresponding to Giraph jobs.
# This is needed as they don't terminate automatically (they hang around consuming memory).
#
# NOTE: this will kill ALL jobs, including ongoing ones!
#
# To get rid of terminated running jobs from Hadoop web interface,
# use "hadoop job -kill job_yyyymmddhhmm_aaaa"

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-hosts.sh

# do a kill on the master separately---this is useful when testing on a single machine
kill -9 $(ps aux | grep "[j]obcache/job_[0-9]\{12\}_[0-9]\{4\}/" | awk '{print $2}')

for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    # [j] is a nifty trick to avoid "grep" showing up as a result
    ssh ${CLUSTER_NAME}$i "kill -9 \$(ps aux | grep \"[j]obcache/job_[0-9]\{12\}_[0-9]\{4\}/\" | awk '{print \$2}')" &
done
wait