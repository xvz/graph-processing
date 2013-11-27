#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

# place input in /user/ubuntu/giraph-input/
# output is in /user/ubuntu/giraph-output/
inputgraph=$(basename $1)

workers=$2    # workers can be > number of EC2 instances

outputdir=/user/ubuntu/giraph-output/pagerank

hadoop dfs -rmr ${outputdir}

hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimplePageRankVertex -c org.apache.giraph.combiner.DoubleSumCombiner -vif org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat -mc org.apache.giraph.examples.SimplePageRankVertex\$SimplePageRankVertexMasterCompute -vip /user/ubuntu/giraph-input/${inputgraph} -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat -op ${outputdir} -w ${workers} 2>&1 | tee -a ./pagerank_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)".txt