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

cd ~/hadoop-1.0.4/conf/

for ((i=1;i<=${nodes};i++)); do
    scp -o StrictHostKeyChecking=no ./* ${name}$i:~/hadoop-1.0.4/conf/
done