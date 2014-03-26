#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 input-graph workers"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2

## log names
# MST can only run in "normal" mode (LALP & dynamic repartitioning cannot be used)
logname=mst_${inputgraph}_${nodes}_0_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# there are 3 versions of MST... according to author, these are:
#
# edgesatrootpjonebyone uses standard Boruvka (no optimizations)
# edgesatselfpjonebyone uses "storing edges at subvertices" (SEAS)
#   -> "edge cleaning on demand" (ECOD) is enabled via flag
# edgeshybridpjonebyone uses SEAS for few iterations then default... but not published
./start-nodes.sh ${nodes} quick-start \
    -ifs /user/${USER}/input/${inputgraph} \
    -hcf "$HADOOP_DIR"/conf/core-site.xml \
    -jc gps.examples.mst.edgesatrootpjonebyone.JobConfiguration \
    -mcfg /user/${USER}/gps-machine-config/machine.cfg \
    -log4jconfig "$GPS_DIR"/conf/log4j.config

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/${USER}/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/${USER}/gps/output/quick-start-machine-stats /user/${USER}/gps/stats-${logname}