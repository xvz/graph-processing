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

logname=pagerank_${inputgraph}_${nodes}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)

## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
# max controls max number of supersteps; must be 30, to match Giraph
./start_nodes.sh ${nodes} quick-start \
    -ifs /user/ubuntu/input/${inputgraph} \
    -hcf /home/ubuntu/hadoop-1.0.4/conf/core-site.xml \
    -jc gps.examples.pagerank.PageRankVertex###JobConfiguration \
    -mcfg /user/ubuntu/gps-machine-config/cs848.cfg \
    -log4jconfig /home/ubuntu/gps-rev-110/conf/log4j.config \
    -other -max###30

## finish logging memory + network usage
./bench_finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/ubuntu/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/ubuntu/gps/output/quick-start-machine-stats /user/ubuntu/gps/stats-${logname}