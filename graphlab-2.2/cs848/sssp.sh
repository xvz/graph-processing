#!/bin/bash -e

if [ $# -ne 4 ]; then
    echo "usage: $0 [input graph] [workers] [async?] [source vertex]"
    exit -1
fi

inputgraph=$(basename $1)
workers=$2
async=$3  # TODO!!!
src=$4

logname=sssp_${inputgraph}_${workers}_${async}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt


## start logging memory + network usage
#./bench_init.sh ${logname}

## start algorithm run
# TODO: superstep? async/sync?
tstart="$(date +%s%N)"
# WARNING: this assumes port 54310... if HDFS is not on this port, change this!!
mpiexec -hostfile ./machines -n ${workers} ../release/toolkits/graph_analytics/sssp --format snap --graph hdfs://$(hostname):54310/user/ubuntu/input/${inputgraph} --source $src --directed 1 2>&1 | tee -a ./logs/${logfile}
tdone="$(date +%s%N)"

echo "TOTAL TIME (ns): $tdone - $tstart" | tee -a ./logs/${logfile}
echo "TOTAL TIME: $(($tdone - $tstart))" | tee -a ./logs/${logfile}

## finish logging memory + network usage
#./bench_finish.sh ${logname}