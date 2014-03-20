#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

# place input in /user/ubuntu/input/
# output is in /user/ubuntu/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2

logname=wcc_${inputgraph}_${nodes}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)

## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
cd ../master-scripts/

# NOTE: numMaxIterations can be set, but we do not set it
# this is to be fair with Giraph and Mizan (both do not max ss termination)
./start_gps_nodes.sh ${nodes} quick-start \
    "-ifs /user/ubuntu/input/${inputgraph} \
     -hcf /home/ubuntu/hadoop-1.0.4/conf/core-site.xml \
     -jc gps.examples.wcc.WeaklyConnectedComponentsVertex###JobConfiguration \
     -mcfg /user/ubuntu/gps-machine-config/cs848.cfg \
     -log4jconfig /home/ubuntu/gps-rev-110/conf/log4j.config"

## finish logging memory + network usage
cd ../cs848/
./bench_finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/ubuntu/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/ubuntu/gps/output/quick-start-machine-stats /user/ubuntu/gps/stats-${logname}