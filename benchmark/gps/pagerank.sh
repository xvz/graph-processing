#!/bin/bash -e

if [ $# -ne 3 ]; then
    echo "usage: $0 input-graph workers gps-mode"
    echo ""
    echo "gps-mode: 0 for normal (no lalp, no dynamic repartitioning)"
    echo "          1 for LALP"
    echo "          2 for dynamic repartitioning"
    echo "          3 for LALP and dynamic repartitioning"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2

mode=$3
case ${mode} in
    0) modeflag="";;
    1) modeflag="-lalp 100";;
    2) modeflag="-dynamic";;
    3) modeflag="-lalp 100 -dynamic";;
    *) echo "Invalid gps-mode"; exit -1;;
esac

## log names
logname=pagerank_${inputgraph}_${nodes}_${mode}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# max controls max number of supersteps; must be 30, to match Giraph
./start-nodes.sh ${nodes} quick-start \
    ${modeflag} \
    -ifs /user/${USER}/input/${inputgraph} \
    -hcf "$HADOOP_DIR"/conf/core-site.xml \
    -jc gps.examples.pagerank.PageRankVertex###JobConfiguration \
    -mcfg /user/${USER}/gps-machine-config/machine.cfg \
    -log4jconfig "$GPS_DIR"/conf/log4j.config \
    -other -max###30

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/${USER}/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/${USER}/gps/output/quick-start-machine-stats /user/${USER}/gps/stats-${logname}