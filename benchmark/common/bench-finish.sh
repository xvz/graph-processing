#!/bin/bash -e

# Finish data logging/collection at the master and all worker machines.

if [ $# -ne 1 ]; then
    echo "usage: $0 log-name-prefix"
    exit -1
fi

source "$(dirname "${BASH_SOURCE[0]}")"/get-hosts.sh

logname=$1
dir=$PWD

for ((i = 0; i <= ${NUM_MACHINES}; i++)); do
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    # special case for master, to make it work for local testing too
    if [ $i -eq  0 ]; then
        name=${HOSTNAME}
    else
        name=${CLUSTER_NAME}${i}
    fi

    # 1. Change to the same directory as master.
    # 2. Append final network usage.
    # 3. Kill sar and free to stop tracking.
    #
    # NOTE: - could use `jobs -p` for kill, but difficult b/c we're ssh-ing
    #       - must escape $ for things that should be evaluated remotely
    ssh ${name} "cd \"$dir\"; cat /proc/net/dev >> ./logs/${nbtfile} & kill \$(pgrep sar) & kill \$(pgrep free)" &
done
wait

# get worker machines' files in parallel, with compression to speed things up
for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    rsync -az ${CLUSTER_NAME}${i}:"$dir"/logs/${logname}_${i}_*.txt ./logs/ &
done
wait