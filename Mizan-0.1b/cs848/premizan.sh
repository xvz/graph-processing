#!/bin/bash -e

# partition type is either 1 (hash) or 2 (range)
if [ $# -ne 3 ]; then
    echo "usage: $0 [input graph] [workers] [partition type]"
    exit -1
fi

inputgraph=$(basename $1)

logfile=premizan-"$(date +%F-%H-%M-%S)".txt


cd ../preMizan/hadoopScripts/

# modified from preMizan/preMizan.sh
case $3 in
    [1]*) ./hadoop_run_modhash.sh $inputgraph $2 true | tee -a ../../cs848/${logfile};;
    [2]*) ./hadoop_run_range.sh $inputgraph $2 true | tee -a ../../cs848/${logfile};;
    *) echo "Error: invalid partition type!";;
esac


