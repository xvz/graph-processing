#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

# place input in /user/ubuntu/input/
# output is in /user/ubuntu/giraph-output/
inputgraph=$(basename $1)

workers=$2    # workers can be > number of EC2 instances

outputdir=/user/ubuntu/giraph-output/pagerank

hadoop dfs -rmr ${outputdir}

## log names
logname=pagerank_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.SimplePageRankVertex -c org.apache.giraph.combiner.DoubleSumCombiner -vif org.apache.giraph.examples.SimplePageRankInputFormat -vip /user/ubuntu/input/${inputgraph} -of org.apache.giraph.examples.SimplePageRankVertex\$SimplePageRankVertexOutputFormat -op ${outputdir} -w ${workers} 2>&1 | tee -a ./logs/${logfile}

# mc not needed b/c we don't want aggregators: -mc org.apache.giraph.examples.SimplePageRankVertex\$SimplePageRankVertexMasterCompute 
# alternative output format: -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat 

## finish logging memory + network usage
./bench_finish.sh ${logname}