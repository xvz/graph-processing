#!/bin/bash

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
else
    echo "Invalid hostname"
    exit
fi


logname=$1
dir=$PWD   # so logs show up in right place

for ((i = 0; i <= ${nodes}; i++)); do
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    # change to same directory as master
    # append final network usage
    ssh ${name}${i} "cd ${dir}; cat /proc/net/dev >> ./${nbtfile}"

    # could use `jobs -p` for kill, but difficult b/c we're ssh-ing
    # must use ''s otherwise $ is evaluated too early
    ssh ${name}${i} 'kill $(pgrep sar)'
done

# get files
for ((i = 0; i <= ${nodes}; i++)); do
    cpufile=${logname}_${i}_cpu.txt   # cpu usage
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    scp ubuntu@${name}${i}:${dir}/${cpufile} ./
    scp ubuntu@${name}${i}:${dir}/${netfile} ./
    scp ubuntu@${name}${i}:${dir}/${memfile} ./
    scp ubuntu@${name}${i}:${dir}/${nbtfile} ./
done