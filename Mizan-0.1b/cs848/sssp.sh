#!/bin/bash -e

if [ $# -ne 3 ]; then
    echo "usage: $0 [input graph] [workers] [dynamic partitioning]"
    exit -1
fi

# input is placed by preMizan into /user/ubuntu/input
# output of preMizan is in /user/ubuntu/m_output/mizan_${inputgraph}_hash/range_${workers}
inputgraph=$(basename $1)

workers=$2    # workers can be > number of EC2 instances
dynamic=$3    # dynamic partitioning

logfile=sssp_${inputgraph}_${workers}_${dynamic}_"$(date +%F-%H-%M-%S)".txt


# -np indicates number of processors
# should probably not go above 2, to avoid contention
#
# pagerank
mpirun -f machines -np ${workers} ../Release/Mizan-0.1b -a 4 -s 100 -u ubuntu -g ${inputgraph} -w ${workers} -m ${dynamic} 2>&1 | tee -a ./${logfile}