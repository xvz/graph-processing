#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 [log-name]"
    exit -1
fi

logname=$1
dir=$PWD

for ((i = 0; i <= 4; i++)); do
    cpufile=${logname}_${i}_cpu.txt   # cpu usage
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    # change to same directory as master
    # start sysstat for cpu, memory, and network usage (1s intervals)
    # print initial network bytes
    # NOTE: & is like variant of ;, so don't need both
    ssh cloud${i} "cd ${dir}; sar 1 > ./${cpufile} & sar -r 1 > ./${memfile} & sar -n DEV 1 > ./${netfile} & cat /proc/net/dev > ./${nbtfile}"
done