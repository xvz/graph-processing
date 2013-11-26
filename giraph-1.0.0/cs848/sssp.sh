#!/bin/bash

# place input in /user/ubuntu/giraph-input/
# output is in /user/ubuntu/giraph-output/
inputgraph=soc-Epinions1-d-n-giraph.txt

# workers can be > number of EC2 instances
workers=8

outputdir=/user/giraph-output/sssp

hadoop dfs -rmr ${outputdir}

hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimpleShortestPathsVertex -vif org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat -vip /user/ubuntu/giraph-input/${inputgraph} -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat -op ${outputdir} -w ${workers} | tee -a ./sssp-"$(date +%F-%H-%M-%S)".txt
