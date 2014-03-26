#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 input-graph workers"
    exit -1
fi

source ../common/get-dirs.sh
source ../common/get-hosts.sh

# place input in /user/${USER}/input/
# output is in /user/${USER}/giraph-output/
inputgraph=$(basename $1)
outputdir=/user/${USER}/giraph-output/
hadoop dfs -rmr "$outputdir" || true

# workers can be > number of EC2 instances, but this is inefficient!
# use more Giraph threads instead (e.g., -Dgiraph.numComputeThreads=N)
workers=$2

## log names
logname=prtolfinder_${inputgraph}_${workers}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # running time


## start logging memory + network usage
#../common/bench-init.sh ${logname}

## start algorithm run
# we use default byte array edges (better performance)
# NOTE: this outputs no data to HDFS
hadoop jar "$GIRAPH_DIR"/giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar org.apache.giraph.GiraphRunner \
    org.apache.giraph.examples.PageRankTolFinderVertex \
    -mc org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexMasterCompute \
    -c org.apache.giraph.combiner.DoubleSumCombiner \
    -ca PageRankTolFinderVertex.maxSS=100 \
    -vif org.apache.giraph.examples.SimplePageRankInputFormat \
    -vip /user/${USER}/input/${inputgraph} \
    -of org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexOutputFormat \
    -op "$outputdir" \
    -w ${workers} 2>&1 | tee -a ./logs/${logfile}

# -wc org.apache.giraph.examples.PageRankTolFinderVertex\$PageRankTolFinderVertexWorkerContext

## finish logging memory + network usage
#../common/bench-finish.sh ${logname}


## get max deltas (changes in PR value) at each superstep
jobid=$(grep "Running job" ./logs/${logfile} | awk '{print $7}')

# The master on a cluster will not have anything---this is for local testing
darray[0]=$(cat "$HADOOP_DIR"/logs/userlogs/${jobid}/*/syslog | grep 'max change' | awk '{print $9}' | tr '\n' ' ')

# NOTE: this is a hack---ZK is located on one of the workers, so just go
# through everyone and we'll get master.compute()'s output exactly once
for ((i = 1; i <= ${nodes}; i++)); do
    darray[${i}]=$(ssh ${name}${i} "cat \"$HADOOP_DIR\"/logs/userlogs/${jobid}/*/syslog | grep 'max change' | awk '{print \$9}' | tr '\n' ' '")
done

deltas=$(echo "${darray[*]}" | sed -e 's/^ *//' -e 's/ *$//')  # join array and strip whitespace

echo "" >> ./tolerances.txt
echo "$(sed 's/-.*//g' <<< ${inputgraph})_deltas = [${deltas}];" >> ./tolerances.txt

## clean up step needed for Giraph
./kill-java-job.sh