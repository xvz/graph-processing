#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/ubuntu/input/
# output is in /user/ubuntu/graphlab-output/
inputgraph=$(basename $1)
outputdir=/user/ubuntu/graphlab-output/
hadoop dfs -rmr ${outputdir}

hdfspath=$(grep hdfs "$HADOOP_DIR"/conf/core-site.xml | sed 's/.*<valued>//g' | sed 's@</value>@@g')

workers=$2
# NOTE: no asynchronous option for this alg

## log names
logname=wcc_${inputgraph}_${workers}_${async}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt


## start logging memory + network usage
../common/bench_init.sh ${logname}

## start algorithm run
tstart="$(date +%s%N)"

mpiexec -f ./machines -n ${workers} \
    "$GRAPHLAB_DIR"/release/toolkits/graph_analytics/connected_component \
    --format adjgps \
    --graph_opts ingress=random \
    --graph ${hdfspath}/user/ubuntu/input/${inputgraph} \
    --saveprefix ${hdfspath}${outputdir} 2>&1 | tee -a ./logs/${logfile}

tdone="$(date +%s%N)"

echo "" | tee -a ./logs/${logfile}
echo "TOTAL TIME (ns): $tdone - $tstart" | tee -a ./logs/${logfile}
echo "TOTAL TIME (sec): $(perl -e "print $(($tdone - $tstart))/1000000000")" | tee -a ./logs/${logfile}

## finish logging memory + network usage
../common/bench_finish.sh ${logname}