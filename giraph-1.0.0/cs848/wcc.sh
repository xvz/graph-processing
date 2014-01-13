#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

# place input in /user/ubuntu/giraph-input/
# output is in /user/ubuntu/giraph-output/
inputgraph=$(basename $1)

workers=$2    # workers can be > number of EC2 instances

outputdir=/user/ubuntu/giraph-output/wcc

hadoop dfs -rmr ${outputdir}

## log names
logname=wcc_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)"
logfile=${logname}.txt       # running time


## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.ConnectedComponentsVertex -vif org.apache.giraph.io.formats.JsonLongLongNullLongVertexInputFormat -vip /user/ubuntu/giraph-input/${inputgraph} -of org.apache.giraph.io.formats.IdWithValueTextOutputFormat -op ${outputdir} -w ${workers} 2>&1 | tee -a ./${logfile}

## finish logging memory + network usage
./bench_finish.sh ${logname}