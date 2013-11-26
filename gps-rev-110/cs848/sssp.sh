#!/bin/bash -e

inputgraph=web-Google.txt
nodes=4     # ec2 instances

./start_gps_nodes.sh ${nodes} quick-start "-ifs /user/ubuntu/gps-input/${inputgraph} -hcf /home/ubuntu/hadoop-1.0.4/conf/core-site.xml -jc gps.examples.sssp.SingleSourceAllVerticesShortestPathVertex###JobConfiguration -mcfg /user/ubuntu/gps-machine-config/cs848.cfg -log4jconfig /home/ubuntu/gps-rev-110/conf/log4j.config -other -max###40"