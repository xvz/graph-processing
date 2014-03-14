#!/bin/bash -e

if [ $# -ne 1 ]; then
    echo "usage: $0 [log-name-prefix]"
    exit -1
fi

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; nodes=4;;
    "cld0") name=cld; nodes=8;;
    "c0") name=c; nodes=16;;
    "cx0") name=cx; nodes=32;;
    "cy0") name=cy; nodes=64;;
    "cz0") name=cz; nodes=128;;
    *) echo "Invalid hostname"; exit -1;;
esac

logname=$1
dir=$PWD   # so logs show up in right place

for ((i = 0; i <= ${nodes}; i++)); do
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    # change to same directory as master
    # append final network usage
    ssh ${name}${i} "cd ${dir}; cat /proc/net/dev >> ./logs/${nbtfile}"

    # could use `jobs -p` for kill, but difficult b/c we're ssh-ing
    # must use ''s otherwise $ is evaluated too early
    ssh ${name}${i} 'kill $(pgrep sar); kill $(pgrep free)'
done

# get files
for ((i = 1; i <= ${nodes}; i++)); do
    # use compression to speed things up
    rsync -avz ubuntu@${name}${i}:${dir}/logs/${logname}_${i}_*.txt ./logs/
done