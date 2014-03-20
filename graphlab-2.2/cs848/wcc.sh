#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

inputgraph=$(basename $1)
workers=$2
# NOTE: no asynchronous option for this alg

# WARNING: this assumes port 54310... if HDFS is not on this port, change this!!
hdfspath=hdfs://$(hostname):54310
outputdir=/user/ubuntu/graphlab-output/
hadoop dfs -rmr ${outputdir}

logname=wcc_${inputgraph}_${workers}_${async}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt


## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
tstart="$(date +%s%N)"

mpiexec -f ./machines -n ${workers} \
    ../release/toolkits/graph_analytics/connected_component \
    --format adjgps \
    --graph_opts ingress=random \
    --graph ${hdfspath}/user/ubuntu/input/${inputgraph} 2>&1 \
    --saveprefix ${hdfspath}${outputdir} | tee -a ./logs/${logfile}

tdone="$(date +%s%N)"

echo "" | tee -a ./logs/${logfile}
echo "TOTAL TIME (ns): $tdone - $tstart" | tee -a ./logs/${logfile}
echo "TOTAL TIME (sec): $(perl -e "print $(($tdone - $tstart))/1000000000")" | tee -a ./logs/${logfile}

## finish logging memory + network usage
./bench_finish.sh ${logname}