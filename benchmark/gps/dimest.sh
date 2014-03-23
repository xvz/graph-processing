#!/bin/bash -e

if [ $# -lt 2 ]; then
    echo "usage: $0 input-graph workers [lalp?] [dynamic migration?]"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2

if [[ $3 -eq 1 ]]; then
    lalp="-lalp 100"
else
    lalp=""
fi

if [[ $4 -eq 1 ]]; then
    dynamic="-dynamic"
else
    dynamic=""
fi

logname=dimest_${inputgraph}_${nodes}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)

## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# max controls max number of supersteps
./start-nodes.sh ${nodes} quick-start \
    -ifs /user/${USER}/input/${inputgraph} \
    -hcf "$HADOOP_DIR"/conf/core-site.xml \
    -jc gps.examples.dimest.DiameterEstimationVertex###JobConfiguration \
    -mcfg /user/${USER}/gps-machine-config/machine.cfg \
    -log4jconfig "$GPS_DIR"/conf/log4j.config \
    "$lalp $dynamic" -other -max###300

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/${USER}/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/${USER}/gps/output/quick-start-machine-stats /user/${USER}/gps/stats-${logname}