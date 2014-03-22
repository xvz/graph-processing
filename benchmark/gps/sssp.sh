#!/bin/bash -e

if [ $# -ne 3 ]; then
    echo "usage: $0 input-graph workers source-vertex"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2
src=$3

logname=sssp_${inputgraph}_${nodes}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)

## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# this sssp assigns edge weight of 1 to all edges
# input graph must have no edge weights
./start-nodes.sh ${nodes} quick-start \
    -ifs /user/${USER}/input/${inputgraph} \
    -hcf "$HADOOP_DIR"/conf/core-site.xml \
    -jc gps.examples.sssp.SingleSourceAllVerticesShortestPathVertex###JobConfiguration \
    -mcfg /user/${USER}/gps-machine-config/machine.cfg \
    -log4jconfig "$GPS_DIR"/conf/log4j.config \
    -other root###${src}

# edgevaluesssp is for when input graph has edge weights
# input graph must have edge weights, but no vertex values
#./start_gps_nodes.sh ${nodes} quick-start -ifs /user/${USER}/input/${inputgraph} -hcf "$HADOOP_DIR"/conf/core-site.xml -jc gps.examples.edgevaluesssp.EdgeValueSSSPVertex###JobConfiguration -mcfg /user/${USER}/gps-machine-config/machine.cfg -log4jconfig "$GPS_DIR"/conf/log4j.config -other root###${src}

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/${USER}/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/${USER}/gps/output/quick-start-machine-stats /user/${USER}/gps/stats-${logname}