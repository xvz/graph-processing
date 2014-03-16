#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

# place input in /user/ubuntu/input/
# output is in /user/ubuntu/giraph-output/
inputgraph=$(basename $1)

workers=$2    # workers can be > number of EC2 instances... but don't do that

outputdir=/user/ubuntu/giraph-output/mst

hadoop dfs -rmr ${outputdir}

## log names
logname=mst_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
#-Dmapred.task.timeout=0 -Dgiraph.zKMinSessionTimeout=0 
hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner -Dmapred.task.timeout=0 org.apache.giraph.examples.MinimumSpanningTreeVertex -vif org.apache.giraph.examples.MinimumSpanningTreeInputFormat -vip /user/ubuntu/input/${inputgraph} -mc org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexMasterCompute -of org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexOutputFormat -op ${outputdir} -w ${workers} 2>&1 | tee -a ./logs/${logfile}

# -wc org.apache.giraph.examples.MinimumSpanningTreeVertex\$MinimumSpanningTreeVertexWorkerContext
# see giraph-core/.../utils/ConfigurationUtils.java for command line opts

## finish logging memory + network usage
./bench_finish.sh ${logname}