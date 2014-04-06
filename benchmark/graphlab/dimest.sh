#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 input-graph machines"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/graphlab-output/
inputgraph=$(basename $1)
outputdir=/user/${USER}/graphlab-output/
hadoop dfs -rmr "$outputdir" || true

hdfspath=$(grep hdfs "$HADOOP_DIR"/conf/core-site.xml | sed -e 's/.*<value>//' -e 's@</value>.*@@')

machines=$2

## log names
# diameter estimation only supports synchronous mode
logname=dimest_${inputgraph}_${machines}_0_"$(date +%Y%m%d-%H%M%S)"
logfile=${logname}_time.txt


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
mpiexec -f ./machines -n ${machines} \
    "$GRAPHLAB_DIR"/release/toolkits/graph_analytics/approximate_diameter \
    --format adjgps \
    --graph_opts ingress=random \
    --graph "$hdfspath"/user/${USER}/input/${inputgraph} 2>&1 | tee -a ./logs/${logfile}
# NOTE: no saveprefix option, diameters/results are outputted to time log

## finish logging memory + network usage
../common/bench-finish.sh ${logname}