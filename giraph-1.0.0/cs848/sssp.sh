#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

# place input in /user/ubuntu/giraph-input/
# output is in /user/ubuntu/giraph-output/
inputgraph=$(basename $1)

workers=$2    # workers can be > number of EC2 instances

outputdir=/user/giraph-output/sssp

hadoop dfs -rmr ${outputdir}

hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimpleShortestPathsVertex -vif org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat -vip /user/ubuntu/giraph-input/${inputgraph} -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat -op ${outputdir} -w ${workers} | tee -a ./sssp-"$(date +%F-%H-%M-%S)".txt
