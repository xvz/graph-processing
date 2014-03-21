#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/ubuntu/input/
# output is in /user/ubuntu/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2

logname=dimest_${inputgraph}_${nodes}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)

## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# max controls max number of supersteps
./start_nodes.sh ${nodes} quick-start \
    -ifs /user/ubuntu/input/${inputgraph} \
    -hcf "$HADOOP_DIR"/conf/core-site.xml \
    -jc gps.examples.dimest.DiameterEstimationVertex###JobConfiguration \
    -mcfg /user/ubuntu/gps-machine-config/machine.cfg \
    -log4jconfig "$GPS_DIR"/conf/log4j.config \
    -other -max###300

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/ubuntu/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/ubuntu/gps/output/quick-start-machine-stats /user/ubuntu/gps/stats-${logname}