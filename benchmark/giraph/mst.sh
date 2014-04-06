#!/bin/bash -e

if [ $# -ne 3 ]; then
    echo "usage: $0 input-graph machines edge-type"
    echo ""
    echo "edge-type: 0 for byte array edges"
    echo "           1 for hash map edges"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/giraph-output/
inputgraph=$(basename $1)
outputdir=/user/${USER}/giraph-output/
hadoop dfs -rmr "$outputdir" || true

# Technically this is the number of "workers", which can be more
# than the number of machines. However, using multiple workers per
# machine is inefficient! Use more Giraph threads instead (see below).
machines=$2

edgetype=$3
case ${edgetype} in
    0) edgeclass="";;     # byte array edges are used by default
    1) edgeclass="-Dgiraph.inputOutEdgesClass=org.apache.giraph.edge.HashMapEdges \
                  -Dgiraph.outEdgesClass=org.apache.giraph.edge.HashMapEdges";;
    *) echo "Invalid edge-type"; exit -1;;
esac

## log names
logname=mst_${inputgraph}_${machines}_${edgetype}_"$(date +%Y%m%d-%H%M%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
# -Dmapred.task.timeout=0 is needed to prevent Giraph job from getting killed after spending 10 mins on one superstep
# Giraph seems to ignore any mapred.task.timeout specified in Hadoop's mapred-site.xml
hadoop jar "$GIRAPH_DIR"/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner \
    ${edgeclass} \
    -Dgiraph.numComputeThreads=4 \
    -Dmapred.task.timeout=0 \
    org.apache.giraph.examples.MinimumSpanningTreeVertex \
    -mc org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexMasterCompute \
    -vif org.apache.giraph.examples.MinimumSpanningTreeInputFormat \
    -vip /user/${USER}/input/${inputgraph} \
    -of org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexOutputFormat \
    -op "$outputdir" \
    -w ${machines} 2>&1 | tee -a ./logs/${logfile}

# -wc org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexWorkerContext
# see giraph-core/.../utils/ConfigurationUtils.java for command line opts (or -h flag to GiraphRunner)

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## clean up step needed for Giraph
./kill-java-job.sh