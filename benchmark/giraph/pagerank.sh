#!/bin/bash -e

if [ $# -ne 3 ]; then
    echo "usage: $0 input-graph workers edge-type"
    echo ""
    echo "edge-type: 0 for byte array edges"
    echo "           1 for hashmap edges"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/giraph-output/
inputgraph=$(basename $1)
outputdir=/user/${USER}/giraph-output/
hadoop dfs -rmr "$outputdir" || true

# workers can be > number of EC2 instances, but this is inefficient!
# use more Giraph threads instead (e.g., -Dgiraph.numComputeThreads=N)
workers=$2

edgetype=$3
case ${edgetype} in
    0) edgeclass="";;     # byte array edges are used by default
    1) edgeclass="-Dgiraph.inputOutEdgesClass=org.apache.giraph.edge.HashMapEdges \
                  -Dgiraph.outEdgesClass=org.apache.giraph.edge.HashMapEdges";;
    *) echo "Invalid edge-type"; exit -1;;
esac

## log names
logname=pagerank_${inputgraph}_${workers}_${edgetype}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
hadoop jar "$GIRAPH_DIR"/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner \
    ${edgeclass} \
    org.apache.giraph.examples.SimplePageRankVertex \
    -c org.apache.giraph.combiner.DoubleSumCombiner \
    -ca SimplePageRankVertex.maxSS=30 \
    -vif org.apache.giraph.examples.SimplePageRankInputFormat \
    -vip /user/${USER}/input/${inputgraph} \
    -of org.apache.giraph.examples.SimplePageRankVertex\$SimplePageRankVertexOutputFormat \
    -op "$outputdir" \
    -w ${workers} 2>&1 | tee -a ./logs/${logfile}

# mc not needed b/c we don't want aggregators: -mc org.apache.giraph.examples.SimplePageRankVertex\$SimplePageRankVertexMasterCompute 
# alternative output format: -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat 

## finish logging memory + network usage
../common/bench-finish.sh ${logname}

## clean up step needed for Giraph
./kill-java-job.sh