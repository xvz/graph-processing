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

cd ~/gps-rev-110/local-master-scripts/
./make_gps_node_runner_jar.sh

cd ~/gps-rev-110/
for ((i=1;i<=${nodes};i++)); do
    scp ./gps_node_runner.jar ${name}$i:~/gps-rev-110/gps_node_runner.jar
done

echo "OK."