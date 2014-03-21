#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [workers]"
    exit -1
fi

source ../common/get-dirs.sh

# place input in /user/ubuntu/input/
# output is in /user/ubuntu/giraph-output/
inputgraph=$(basename $1)
outputdir=/user/ubuntu/giraph-output/
hadoop dfs -rmr ${outputdir}

# workers can be > number of EC2 instances, but this is inefficient!
# use more Giraph threads instead (e.g., -Dgiraph.numComputeThreads=N)
workers=$2

## log names
logname=prtolfinder_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
#../common/bench-init.sh ${logname}

## start algorithm run
hadoop jar $GIRAPH_DIR/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner \
    org.apache.giraph.examples.PageRankTolFinderVertex \
    -mc org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexMasterCompute \
    -c org.apache.giraph.combiner.DoubleSumCombiner \
    -ca PageRankTolFinderVertex.maxSS=100 \
    -vif org.apache.giraph.examples.SimplePageRankInputFormat \
    -vip /user/ubuntu/input/${inputgraph} \
    -of org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexOutputFormat \
    -op ${outputdir} \
    -w ${workers} 2>&1 | tee -a ./logs/${logfile}

# -wc org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexWorkerContext

## finish logging memory + network usage
#../common/bench-finish.sh ${logname}

# TODO: get zookeeper id from log
jobid=$(grep "Running job" ./logs/${logfile} | awk '{print $7}')
deltas=$(cat $HADOOP_DIR/logs/userlogs/${jobid}/*/syslog | grep "max change" | awk '{print $8}' | tr '\n' ' ')

echo "" >> ./tolerances.txt
echo "$(sed 's/-.*//g' <<< ${inputgraph})_deltas = [${deltas}];" >> ./tolerances.txt

## clean up step needed for Giraph
./kill-java-job.sh
