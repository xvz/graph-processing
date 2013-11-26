#!/bin/bash

# place input in /user/ubuntu/giraph-input/
# output is in /user/ubuntu/giraph-output/
inputgraph=tinygraph.txt
workers=10

hadoop dfs -rmr ./giraph-output/sssp
hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimpleShortestPathsVertex -vif org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat -vip /user/ubuntu/giraph-input/${inputgraph} -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat -op /user/ubuntu/giraph-output/ssssp -w ${workers}
