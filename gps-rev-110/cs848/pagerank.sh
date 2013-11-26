#!/bin/bash -e

# place input in /user/ubuntu/gps-input/
# output is in /user/ubuntu/gps/output/
inputgraph=soc-Epinions1-d-n.txt # LiveJournal01.txt

# nodes should be number of EC2 instances
nodes=4

cd ../master-scripts/

# NOTE: max controls max number of supersteps
./start_gps_nodes.sh ${nodes} quick-start "-ifs /user/ubuntu/gps-input/${inputgraph} -hcf /home/ubuntu/hadoop-1.0.4/conf/core-site.xml -jc gps.examples.pagerank.PageRankVertex###JobConfiguration -mcfg /user/ubuntu/gps-machine-config/cs848.cfg -log4jconfig /home/ubuntu/gps-rev-110/conf/log4j.config -other -max###300"
