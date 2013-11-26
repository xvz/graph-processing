#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [ec2 nodes]"
    exit -1
fi

# place input in /user/ubuntu/gps-input/
# output is in /user/ubuntu/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2

cd ../master-scripts/

# NOTE: max controls max number of supersteps
./start_gps_nodes.sh ${nodes} quick-start "-ifs /user/ubuntu/gps-input/${inputgraph} -hcf /home/ubuntu/hadoop-1.0.4/conf/core-site.xml -jc gps.examples.sssp.SingleSourceAllVerticesShortestPathVertex###JobConfiguration -mcfg /user/ubuntu/gps-machine-config/cs848.cfg -log4jconfig /home/ubuntu/gps-rev-110/conf/log4j.config -other -max###100"