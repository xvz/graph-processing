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
    exit
fi

cd ~/giraph-1.0.0/

mvn clean install -Phadoop_1.0 -DskipTests -pl giraph-examples -Dfindbugs.skip
#,giraph-core


for ((i=1;i<=${nodes};i++)); do
    scp ./giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar ${name}$i:~/giraph-1.0.0/giraph-examples/target/

    scp ./giraph-core/target/giraph-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar ${name}$i:~/giraph-1.0.0/giraph-core/target/
done

echo "OK."