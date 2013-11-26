#!/bin/bash -e

# input is placed by preMizan into /user/ubuntu/input
# output of preMizan is in /user/ubuntu/m_output/mizan_${inputgraph}_hash/range_${workers}
inputgraph=web-Google.txt

# workers can be > number of EC2 instances
workers=4

# dynamic partitioning
dynamic=1

logfile=pagerank-"$(date +%F-%H-%M-%S)".txt

read -p "preMizan? (y/n): " pre

if [[ "$pre" == "y" ]]; then
    cd ../preMizan/
    ./preMizan.sh ../cs848/${inputgraph} ${workers} | tee -a ./${logfile}
fi

# -np indicates number of processors
# should probably not go above 2, to avoid contention
#
# pagerank
mpirun -f machines -np ${workers} ../Release/Mizan-0.1b -a 1 -s 300 -u ubuntu -g ${inputgraph} -w ${workers} -m ${dynamic} | tee -a ./${logfile}