#!/bin/bash -e

nodes=4

cd ~/giraph-1.0.0/

for ((i=1;i<=${nodes};i++)); do
    scp ./giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar cloud$i:~/giraph-1.0.0/giraph-examples/target/

    scp ./giraph-core/target/giraph-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar cloud$i:~/giraph-1.0.0/giraph-core/target/
done