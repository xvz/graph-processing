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
logname=prtolfinder_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
#./bench_init.sh ${logname}

## start algorithm run
hadoop jar $GIRAPH_HOME/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner org.apache.giraph.examples.PageRankTolFinderVertex -mc org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexMasterCompute -c org.apache.giraph.combiner.DoubleSumCombiner -vif org.apache.giraph.examples.SimplePageRankInputFormat -vip /user/ubuntu/input/${inputgraph} -of org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexOutputFormat -op ${outputdir} -w ${workers} 2>&1 | tee -a ./logs/${logfile}

# -wc org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexWorkerContext

## finish logging memory + network usage
#./bench_finish.sh ${logname}

jobid=$(grep "Running job" ./logs/${logfile} | awk '{print $7}')
deltas=$(cat ~/hadoop-1.0.4/logs/userlogs/${jobid}/*/syslog | grep "max change" | awk '{print $8}' | tr '\n' ' ')

echo "" >> ./tolerances.txt
echo "$(sed 's/-.*//g' <<< ${inputgraph})_deltas = [${deltas}];" >> ./tolerances.txt

## clean up step needed for Giraph
./kill_java_job.sh
