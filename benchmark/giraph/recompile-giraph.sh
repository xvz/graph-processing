#!/bin/bash -e

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; nodes=4;;
    "cld0") name=cld; nodes=8;;
    "c0") name=c; nodes=16;;
    "cx0") name=cx; nodes=32;;
    "cy0") name=cy; nodes=64;;
    "cz0") name=cz; nodes=128;;
    *) echo "Invalid hostname"; exit -1;;
esac

cd ~/giraph-1.0.0/

# -pl specifies what packages to compile (e.g., giraph-examples,giraph-core)
# -Dfindbugs.skip skips "find bugs" stage (saves quite a bit of time)
mvn clean install -Phadoop_1.0 -DskipTests -pl giraph-examples -Dfindbugs.skip


for ((i = 1; i <= ${nodes}; i++)); do
    scp ./giraph-examples/target/giraph-examples-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar ${name}$i:~/giraph-1.0.0/giraph-examples/target/ &

    scp ./giraph-core/target/giraph-1.0.0-for-hadoop-1.0.2-jar-with-dependencies.jar ${name}$i:~/giraph-1.0.0/giraph-core/target/ &
done
wait

echo "OK."