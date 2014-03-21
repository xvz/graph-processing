#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/giraph-output/
inputgraph=$(basename $1)
outputdir=/user/${USER}/giraph-output/
hadoop dfs -rmr ${outputdir} || true

# workers can be > number of EC2 instances, but this is inefficient!
# use more Giraph threads instead (e.g., -Dgiraph.numComputeThreads=N)
workers=$2    

## log names
logname=dimest_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
hadoop jar "$GIRAPH_DIR"/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner \
    org.apache.giraph.examples.DiameterEstimationVertex \
    -ca DiameterEstimationVertex.maxSS=300 \
    -vif org.apache.giraph.examples.DiameterEstimationInputFormat \
    -vip /user/${USER}/input/${inputgraph} \
    -of org.apache.giraph.examples.DiameterEstimationVertex\$DiameterEstimationVertexOutputFormat \
    -op ${outputdir} \
    -w ${workers} 2>&1 | tee -a ./logs/${logfile}

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## clean up step needed for Giraph
./kill-java-job.sh