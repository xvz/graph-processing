#!/bin/bash -e

if [ $# -ne 3 ]; then
    echo "usage: $0 [input graph] [workers] [async?]"
    exit -1
fi

inputgraph=$(basename $1)
workers=$2
async=$3

if [[ ${async} == 1 ]]; then
    mode="async"
else
    mode="sync"
fi

logname=pagerank_${inputgraph}_${workers}_${async}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt


## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
# TODO: superstep? async/sync?
tstart="$(date +%s%N)"
# WARNING: this assumes port 54310... if HDFS is not on this port, change this!!
mpiexec -hostfile ./machines -n ${workers} ../release/toolkits/graph_analytics/pagerank --engine ${mode} --format adjgps --graph hdfs://$(hostname):54310/user/ubuntu/input/${inputgraph} --tol 0.005 2>&1 | tee -a ./logs/${logfile}
tdone="$(date +%s%N)"

echo "TOTAL TIME (ns): $tdone - $tstart" | tee -a ./logs/${logfile}
echo "TOTAL TIME: $(($tdone - $tstart))" | tee -a ./logs/${logfile}

## finish logging memory + network usage
./bench_finish.sh ${logname}