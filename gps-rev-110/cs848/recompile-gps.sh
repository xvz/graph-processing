#!/bin/bash -e

hostname=$(hostname)

if [[ "$hostname" == "cloud0" ]]; then
    name=cloud
    nodes=4
elif [[ "$hostname" == "cld0" ]]; then
    name=cld
    nodes=8
elif [[ "$hostname" == "c0" ]]; then
    name=c
    nodes=16
else
    echo "Invalid hostname"
    exit -1
fi

cd ~/gps-rev-110/local-master-scripts/
./make_gps_node_runner_jar.sh

cd ~/gps-rev-110/
for ((i=1;i<=${nodes};i++)); do
    scp ./gps_node_runner.jar ${name}$i:~/gps-rev-110/gps_node_runner.jar
done

echo "OK."