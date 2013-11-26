#!/bin/bash -e

nodes=4

cd ~/hadoop-1.0.4/conf/

for ((i=1;i<=${nodes};i++)); do
    scp ./* cloud$i:~/hadoop-1.0.4/conf/
done