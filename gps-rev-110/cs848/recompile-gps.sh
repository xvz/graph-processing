#!/bin/bash -e

name=cloud
nodes=4

cd ~/gps-rev-110/local-master-scripts/
./make_gps_node_runner_jar.sh

cd ~/gps-rev-110/
for ((i=1;i<=${nodes};i++)); do
    scp ./gps_node_runner.jar $name$i:~/gps-rev-110/gps_node_runner.jar
done