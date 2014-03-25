#!/bin/bash -e

if [ $# -lt 3 ]; then
    echo "usage: $0 input-graph workers source-vertex [lalp?] [dynamic migration?]"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2
src=$3

if [[ $4 -eq 1 ]]; then
    lalp="-lalp 100"
else
    lalp=""
fi

if [[ $5 -eq 1 ]]; then
    dynamic="-dynamic"
else
    dynamic=""
fi

logname=sssp_${inputgraph}_${nodes}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)

## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# This SSSP assigns edge weight of 1 to all edges, without using
# the boolean trick of SingleSourceAllVerticesShortestPathVertex.
# Input graph must not have edge weights.
./start-nodes.sh ${nodes} quick-start \
    -ifs /user/${USER}/input/${inputgraph} \
    -hcf "$HADOOP_DIR"/conf/core-site.xml \
    -jc gps.examples.sssp.SSSPVertex###JobConfiguration \
    -mcfg /user/${USER}/gps-machine-config/machine.cfg \
    -log4jconfig "$GPS_DIR"/conf/log4j.config \
    "$lalp $dynamic" -other -root###${src}

# edgevaluesssp is for when input graph has edge weights
# input graph must have edge weights, but no vertex values
#./start_gps_nodes.sh ${nodes} quick-start -ifs /user/${USER}/input/${inputgraph} -hcf "$HADOOP_DIR"/conf/core-site.xml -jc gps.examples.edgevaluesssp.EdgeValueSSSPVertex###JobConfiguration -mcfg /user/${USER}/gps-machine-config/machine.cfg -log4jconfig "$GPS_DIR"/conf/log4j.config -other root###${src}

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/${USER}/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/${USER}/gps/output/quick-start-machine-stats /user/${USER}/gps/stats-${logname}