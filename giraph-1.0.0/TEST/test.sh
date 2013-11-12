#!/bin/bash

hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimpleShortestPathsVertex -vif org.apache.giraph.io.formats.JsonLongDoubleFloatDoubleVertexInputFormat -vip /user/ubuntu/giraph-input/tiny_graph.txt -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat -op /user/ubuntu/giraph-output/shortestpaths -w 4
