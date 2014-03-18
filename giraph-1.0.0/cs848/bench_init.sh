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
dir=$PWD

for ((i = 0; i <= ${nodes}; i++)); do
    cpufile=${logname}_${i}_cpu.txt   # cpu usage
    netfile=${logname}_${i}_net.txt   # network usage
    memfile=${logname}_${i}_mem.txt   # memory usage
    nbtfile=${logname}_${i}_nbt.txt   # network bytes total

    # change to same directory as master
    # start sysstat for cpu and network usage; free for memory usage (1s intervals)
    # print initial network bytes
    #
    # NOTE: & is like variant of ;, so don't need both
    # NOTE: grep needs stdbuf correction, otherwise nothing shows up
    ssh ${name}${i} "cd ${dir}; sar 1 > ./logs/${cpufile} & free -s 1 | stdbuf -o0 grep + > ./logs/${memfile} & sar -n DEV 1 | stdbuf -o0 grep 'lo\|eth0' > ./logs/${netfile} & cat /proc/net/dev > ./logs/${nbtfile}" &
done
wait