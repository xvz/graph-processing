#!/bin/bash

# partition type is either 1 (hash) or 2 (range)
if [ $# -ne 3 ]; then
    echo "usage: $0 [input graph] [workers] [partition type]"
    exit -1
fi

inputgraph=$(basename $1)

logname=premizan_${inputgraph}_${2}_${3}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt

## start logging memory + network usage
./bench_init.sh ${logname}

cd ../preMizan/hadoopScripts/

## start premizan conversion
tstart="$(date +%s%N)"

# modified from preMizan/preMizan.sh
case $3 in
    [1]*) ./hadoop_run_modhash.sh $inputgraph $2 true 2>&1 | tee -a ../../cs848/logs/${logfile};;
    [2]*) ./hadoop_run_range.sh $inputgraph $2 true 2>&1 | tee -a ../../cs848/logs/${logfile};;
    *) echo "Error: invalid partition type!";;
esac

tdone="$(date +%s%N)"

cd ../../cs848/

echo "" | tee -a ./logs/${logfile}
echo "TOTAL TIME (ns): $tdone - $tstart" | tee -a ./logs/${logfile}
echo "TOTAL TIME (sec): $(perl -e "print $(($tdone - $tstart))/1000000000")" | tee -a ./logs/${logfile}

## finish logging memory + network usage
./bench_finish.sh ${logname}