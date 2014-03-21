#!/bin/bash -e

# Performs Mizan's prepartitioning phase. This is mandatory as
# Mizan expects input to be pre-partitioned in a specific way.

# partition type is either 1 (hash) or 2 (range)
if [ $# -ne 3 ]; then
    echo "usage: $0 [input graph] [workers] [partition type]"
    exit -1
fi

source ../common/get-dirs.sh

# absolute path to this script's location
scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)


# place input into /user/${USER}/input/ (this is where preMizan looks)
# output of preMizan is in /user/${USER}/m_output/mizan_${inputgraph}_mhash_${workers}/
#  (or _mrange_${workers} if using range partitioning)
inputgraph=$(basename $1)

logname=premizan_${inputgraph}_${2}_${3}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt

## start logging memory + network usage
../common/bench-init.sh ${logname}

cd "$MIZAN_DIR"/preMizan/hadoopScripts/

## start premizan conversion
tstart="$(date +%s%N)"

# taken from preMizan/preMizan.sh
case $3 in
    [1]*) ./hadoop_run_modhash.sh $inputgraph $2 true 2>&1 | tee -a "$scriptdir"/logs/${logfile};;
    [2]*) ./hadoop_run_range.sh $inputgraph $2 true 2>&1 | tee -a "$scriptdir"/logs/${logfile};;
    *) echo "Error: invalid partition type!";;
esac

tdone="$(date +%s%N)"

cd "$scriptdir"

echo "" | tee -a ./logs/${logfile}
echo "TOTAL TIME (ns): $tdone - $tstart" | tee -a ./logs/${logfile}
echo "TOTAL TIME (sec): $(perl -e "print $(($tdone - $tstart))/1000000000")" | tee -a ./logs/${logfile}

## finish logging memory + network usage
../common/bench-finish.sh ${logname}