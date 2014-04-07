#!/bin/bash -e

# Checks to ensure all log files are present.
#
# A simple way to use this is "./log-checker.sh *time.txt".
#
# Note that the *_0_mem.txt matching is useful for spotting failed
# runs too, as bench-init runs before the time log is created.

if [ $# -lt 1 ]; then
    echo "usage: $0 time/mem-log [time/mem-log ...]"
    echo ""
    echo "time/mem-log: experiment's time log file OR master's mem file"
    echo "          (e.g. pagerank_orkut-adj.txt_16_20140101-123050_time.txt)"
    echo "          ( OR  pagerank_orkut-adj.txt_16_20140101-123050_0_mem.txt)"
    exit -1
fi

dir=$PWD

# read args into array of files
read -a FILES <<< $(echo "$@")

for file in "${FILES[@]}"; do
    logname=$(echo $(basename "$file") | sed -e 's/_time.txt$//g' -e 's/_0_mem.txt$//g')

    # move to where the logs are
    cd "$dir/$(dirname "$file")"

    err="$logname\n"
    iserr=0

    # check if all files are present
    if [[ ! -f "${logname}_time.txt" ]]; then
        err="$err  ERROR: ${logname}_time.txt missing!\n"
        iserr=1
    fi

    machines=$(echo "$logname" | sed 's/_/ /g' | awk '{print $3}')

    for (( i = 0; i <= ${machines}; i++ )); do
        if [[ ! -f "${logname}_${i}_mem.txt" ]]; then
            err="$err  ERROR: ${logname}_${i}_mem.txt missing!\n"
            iserr=1
        elif [[ ! -f "${logname}_${i}_nbt.txt" ]]; then
            err="$err  ERROR: ${logname}_${i}_nbt.txt missing!\n"
            iserr=1
        elif [[ ! -f "${logname}_${i}_cpu.txt" ]]; then
            err="$err  WARNING: ${logname}_${i}_cpu.txt missing!\n"
            iserr=1
        elif [[ ! -f "${logname}_${i}_net.txt" ]]; then
            err="$err  WARNING: ${logname}_${i}_net.txt missing!\n"
            iserr=1
        fi
    done

    # only print something when there's an error
    if [[ $iserr -eq 1 ]]; then
        echo -e "$err"
    fi
done