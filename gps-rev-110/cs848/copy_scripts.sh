#!/bin/bash -e

cd ../scripts/

while read slave; do
    scp ./start_gps_node.sh $slave:$PWD/ &
    scp ./stop_gps_node.sh $slave:$PWD/ &
done < ../cs848/slaves
wait

echo "ssh to $(tail -n 1 ../cs848/slaves) and remove '&' in start_gps_node.sh!!"