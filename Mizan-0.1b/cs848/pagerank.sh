#!/bin/bash -e

# input is placed by preMizan
inputgraph=web-Google.txt
workers=10
nodes=4     # ec2 instances

# dynamic partitioning
dynamic=1

read -p "preMizan? (y/n): " pre

if [[ "$pre" == "y" ]]; then
    ../preMizan/preMizan.sh ${inputgraph} ${nodes}
fi

# -np indicates number of processors
# should probably not go above 2, to avoid contention
#
# pagerank
mpirun -f machines -np 2 ../Release/Mizan-0.1b -a 1 -s 100 -u ubuntu -g ${inputgraph} -w ${workers} -m ${dynamic} | tee -a ./pagerank-"$(date +%F-%H-%M-%S)".txt