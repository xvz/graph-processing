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
logname=mst_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# -Dmapred.task.timeout=0 can be used to prevent Giraph job from getting killed after spending 10 mins on one superstep
# Giraph seems to ignore any mapred.task.timeout specified in Hadoop's mapred-site.xml
hadoop jar "$GIRAPH_DIR"/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner \
    -Dgiraph.inputOutEdgesClass=org.apache.giraph.edge.HashMapEdges \
    -Dgiraph.outEdgesClass=org.apache.giraph.edge.HashMapEdges \
    org.apache.giraph.examples.MinimumSpanningTreeVertex \
    -mc org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexMasterCompute \
    -vif org.apache.giraph.examples.MinimumSpanningTreeInputFormat \
    -vip /user/${USER}/input/${inputgraph} \
    -of org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexOutputFormat \
    -op ${outputdir} \
    -w ${workers} 2>&1 | tee -a ./logs/${logfile}

# -wc org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexWorkerContext
# see giraph-core/.../utils/ConfigurationUtils.java for command line opts (or -h flag to GiraphRunner)

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## clean up step needed for Giraph
./kill-java-job.sh