#!/bin/bash -e

if [ $# -ne 4 ]; then
    echo "usage: $0 input-graph workers source-vertex migration-mode"
    exit -1
fi

source ../common/get-dirs.sh

# place input into /user/${USER}/input/ (this is where preMizan looks)
# output of preMizan is in /user/${USER}/m_output/mizan_${inputgraph}_mhash_${workers}/
#  (or _mrange_${workers} if using range partitioning)
# output of algorithm is in /user/${USER}/mizan-output/
inputgraph=$(basename $1)

workers=$2    # workers can be > number of EC2 instances
src=$3
dynamic=$4    # dynamic partitioning

logname=sssp_${inputgraph}_${workers}_${dynamic}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # Mizan stats (incl. running time)


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
mpirun -f machines -np ${workers} "$MIZAN_DIR"/Release/Mizan-0.1b \
    -a 5 \
    --src ${src} \
    -u ${USER} \
    -g ${inputgraph} \
    -w ${workers} \
    -m ${dynamic} 2>&1 | tee -a ./logs/${logfile}

## finish logging memory + network usage
../common/bench-finish.sh ${logname}