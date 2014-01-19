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
elif [[ "$hostname" == "cx0" ]]; then
    name=cx
    nodes=32
else
    echo "Invalid hostname"
    exit -1
fi

for ((i=1;i<=${nodes};i++)); do
    sudo scp -o StrictHostKeyChecking=no /etc/hosts ${name}$i:/etc/hosts
    sudo ssh -o StrictHostKeyChecking=no ${name}$i "echo \"${name}${i}\" > /etc/hostname"
done