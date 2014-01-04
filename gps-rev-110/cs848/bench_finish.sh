#!/bin/bash

if [ $# -ne 1 ]; then
    echo "usage: $0 [log-name]"
    exit -1
fi

logname=$1

dir=$PWD   # so logs show up in right place

for ((i = 1; i <= 4; i++)); do
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage

    # change to same directory as master
    # append final network usage
    # could use `jobs -p` for kill, but difficult b/c we're ssh-ing
    ssh cloud${i} "cd ${dir}; cat /proc/net/dev >> ./${netfile}; kill $(ps -e | grep sar | sed 's/ .*//g')"
done

# get files
for ((i = 1; i <= 4; i++)); do
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage

    scp ubuntu@cloud${i}:${dir}/${netfile} ./
    scp ubuntu@cloud${i}:${dir}/${memfile} ./
done