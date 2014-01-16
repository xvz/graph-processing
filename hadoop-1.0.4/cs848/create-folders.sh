#!/bin/bash

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

for ((i=1;i<=${nodes};i++)); do
    ssh -o StrictHostKeyChecking=no ${name}$i "mkdir -p ~/giraph-1.0.0/cs848/logs"
    ssh -o StrictHostKeyChecking=no ${name}$i "mkdir -p ~/gps-rev-110/cs848/logs"
    ssh -o StrictHostKeyChecking=no ${name}$i "mkdir -p ~/Mizan-0.1bu1/cs848/logs"
done