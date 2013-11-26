#!/bin/bash

# place input in /user/ubuntu/giraph-input/
# output is in /user/ubuntu/giraph-output/
inputgraph=tinygraph.txt
workers=10

hadoop dfs -rmr ./giraph-output/pagerank
hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimplePageRankVertex -c org.apache.giraph.combiner.DoubleSumCombiner -vif org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat -mc org.apache.giraph.examples.SimplePageRankVertex\$SimplePageRankVertexMasterCompute -vip /user/ubuntu/giraph-input/${inputgraph} -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat -op /user/ubuntu/giraph-output/pagerank -w ${workers}
