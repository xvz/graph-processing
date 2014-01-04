#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 [log-name]"
    exit -1
fi

logname=$1
dir=$PWD

for ((i = 1; i <= 4; i++)); do
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage

    # change to same directory as master
    # start sysstat for memory, 1s intervals
    # print initial network usage
    ssh cloud${i} "cd ${dir}; sar -r 1 > ./${memfile}&; cat /proc/net/dev > ./${netfile}"
done