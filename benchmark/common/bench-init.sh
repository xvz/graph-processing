#!/bin/bash -e

# Initiate data logging/collection at the master and all worker machines.

if [ $# -ne 1 ]; then
    echo "usage: $0 log-name-prefix"
    exit -1
fi

source "$(dirname "${BASH_SOURCE[0]}")"/get-hosts.sh

logname=$1
dir=$PWD

for ((i = 0; i <= ${NUM_MACHINES}; i++)); do
    cpufile=${logname}_${i}_cpu.txt   # cpu usage
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    # special case for master, to make it work for local testing too
    if [ $i -eq  0 ]; then
        name=${HOSTNAME}
    else
        name=${CLUSTER_NAME}${i}
    fi

    # 1. Change to the same directory as master.
    # 2. Start sysstat for cpu and network usage, and free for memory usage (1s intervals).
    # 3. Print initial network bytes.
    #
    # NOTE: - & is like variant of ;, so don't need both
    #       - grep needs stdbuf correction, otherwise nothing shows up
    ssh ${name} "cd \"$dir\"; sar 1 > ./logs/${cpufile} & free -s 1 | stdbuf -o0 grep + > ./logs/${memfile} & sar -n DEV 1 | stdbuf -o0 grep 'lo\|eth0' > ./logs/${netfile} & cat /proc/net/dev > ./logs/${nbtfile}" &
done
wait