#!/bin/bash -e

if [ $# -ne 4 ]; then
    echo "usage: $0 input-graph machines gps-mode source-vertex"
    echo ""
    echo "gps-mode: 0 for normal (no lalp, no dynamic repartitioning)"
    echo "          1 for LALP"
    echo "          2 for dynamic repartitioning"
    echo "          3 for LALP and dynamic repartitioning"
    exit -1
fi

source ../common/get-dirs.sh
source ../common/get-configs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/gps/output/
inputgraph=$(basename $1)

# machines should be number of EC2 instances
machines=$2
workers=$(($machines * $GPS_WPM))

# NOTE: we can only use LALP for SSSP when ALL edge weights are the
# same for the entire graph. In our case, all edge weights are 1.
mode=$3
case ${mode} in
    0) modeflag="";;
    1) modeflag="-lalp 100";;
    2) modeflag="-dynamic";;
    3) modeflag="-lalp 100 -dynamic";;
    *) echo "Invalid gps-mode"; exit -1;;
esac

src=$4

## log names
logname=sssp_${inputgraph}_${machines}_${mode}_"$(date +%Y%m%d-%H%M%S)"
logfile=${logname}_time.txt       # GPS statistics (incl running time)


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# This SSSP assigns edge weight of 1 to all edges, without using
# the boolean trick of SingleSourceAllVerticesShortestPathVertex.
# Input graph must not have edge weights.
./start-nodes.sh ${workers} quick-start \
    ${modeflag} \
    -ifs /user/${USER}/input/${inputgraph} \
    -hcf "$HADOOP_DIR"/conf/core-site.xml \
    -jc gps.examples.sssp.SSSPVertex###JobConfiguration \
    -mcfg /user/${USER}/gps-machine-config/machine.cfg \
    -log4jconfig "$GPS_DIR"/conf/log4j.config \
    -other -root###${src}

# gps.examples.edgevaluesssp.EdgeValueSSSPVertex###JobConfiguration
# is for when input graph has edge weights.
# input graph must have edge weights, but no vertex values

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/${USER}/gps/output/quick-start-machine-stats ./logs/${logfile}
#hadoop dfs -mv /user/${USER}/gps/output/quick-start-machine-stats /user/${USER}/gps/stats-${logname}