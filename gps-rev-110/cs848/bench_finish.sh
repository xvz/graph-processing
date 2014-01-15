#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 [log-name]"
    exit -1
fi

logname=$1

dir=$PWD   # so logs show up in right place

for ((i = 1; i <= 2; i++)); do
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    # change to same directory as master
    # append final network usage
    ssh cloud${i} "cd ${dir}; cat /proc/net/dev >> ./${nbtfile}"

    # could use `jobs -p` for kill, but difficult b/c we're ssh-ing
    # must use ''s otherwise $ is evaluated too early
    ssh cloud${i} 'kill $(pgrep sar)'
done

# get files
for ((i = 1; i <= 2; i++)); do
    cpufile=${logname}_${i}_cpu.txt   # cpu usage
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    scp ubuntu@cloud${i}:${dir}/${cpufile} ./
    scp ubuntu@cloud${i}:${dir}/${netfile} ./
    scp ubuntu@cloud${i}:${dir}/${memfile} ./
    scp ubuntu@cloud${i}:${dir}/${nbtfile} ./
done