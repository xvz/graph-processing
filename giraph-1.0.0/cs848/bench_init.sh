#!/bin/bash -e

if [ $# -ne 1 ]; then
    echo "usage: $0 [log-name]"
    exit -1
fi

hostname=$(hostname)

if [[ "$hostname" == "cloud0" ]]; then
    name=cloud
    nodes=4
elif [[ "$hostname" == "cld0" ]]; then
    name=cld
    nodes=8
elif [[ "$hostname" == "c0" ]]; then
    name=c
    nodes=16
elif [[ "$hostname" == "cx0" ]]; then
    name=cx
    nodes=32
else
    echo "Invalid hostname"
    exit -1
fi


logname=$1
dir=$PWD

for ((i = 0; i <= ${nodes}; i++)); do
    cpufile=${logname}_${i}_cpu.txt   # cpu usage
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    # change to same directory as master
    # start sysstat for cpu, memory, and network usage (1s intervals)
    # print initial network bytes
    # NOTE: & is like variant of ;, so don't need both
    ssh ${name}${i} "cd ${dir}; sar 1 > ./logs/${cpufile} & sar -r 1 > ./logs/${memfile} & sar -n DEV 1 > ./logs/${netfile} & cat /proc/net/dev > ./logs/${nbtfile}"
done