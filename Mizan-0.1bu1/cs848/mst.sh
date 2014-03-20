#!/bin/bash

if [ $# -ne 3 ]; then
    echo "usage: $0 [input graph] [workers] [dynamic partitioning]"
    exit -1
fi

# input is placed by preMizan into /user/ubuntu/input
# output of preMizan is in /user/ubuntu/m_output/mizan_${inputgraph}_hash/range_${workers}
inputgraph=$(basename $1)

workers=$2    # workers can be > number of EC2 instances
dynamic=$3    # dynamic partitioning

logname=mst_${inputgraph}_${workers}_${dynamic}_"$(date +%F-%H-%M-%S)"
logfile=${logname}_time.txt       # Mizan stats (incl. running time)


## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
mpirun -f machines -np ${workers} ../Release/Mizan-0.1b \
    -a 7 \
    -u ubuntu \
    -g ${inputgraph} \
    -w ${workers} \
    -m ${dynamic} 2>&1 | tee -a ./logs/${logfile}

## finish logging memory + network usage
./bench_finish.sh ${logname}