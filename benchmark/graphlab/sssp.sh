#!/bin/bash -e

if [ $# -ne 4 ]; then
    echo "usage: $0 [input graph] [workers] [source vertex] [async?]"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/graphlab-output/
inputgraph=$(basename $1)
outputdir=/user/${USER}/graphlab-output/
hadoop dfs -rmr ${outputdir} || true

hdfspath=$(grep hdfs "$HADOOP_DIR"/conf/core-site.xml | sed 's/.*<value>//g' | sed 's@</value>@@g')

workers=$2
src=$3
async=$4

if [[ ${async} -eq 1 ]]; then
    mode="async"
else
    mode="sync"
fi

## log names
logname=sssp_${inputgraph}_${workers}_${async}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
tstart="$(date +%s%N)"

mpiexec -f ./machines -n ${workers} \
    "$GRAPHLAB_DIR"/release/toolkits/graph_analytics/sssp \
    --source $src \
    --directed 1 \
    --engine ${mode} \
    --format adjgps \
    --graph_opts ingress=random \
    --graph ${hdfspath}/user/${USER}/input/${inputgraph} \
    --saveprefix ${hdfspath}${outputdir} 2>&1 | tee -a ./logs/${logfile}

tdone="$(date +%s%N)"

echo "" | tee -a ./logs/${logfile}
echo "TOTAL TIME (ns): $tdone - $tstart" | tee -a ./logs/${logfile}
echo "TOTAL TIME (sec): $(perl -e "print $(($tdone - $tstart))/1000000000")" | tee -a ./logs/${logfile}

## finish logging memory + network usage
../common/bench-finish.sh ${logname}