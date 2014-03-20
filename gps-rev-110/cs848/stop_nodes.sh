#!/bin/bash

# does the same thing as ../master-scripts/stop_gps_nodes.sh but faster
../scripts/stop_gps_node.sh

while read slave; do
    ssh $slave "$PWD/../scripts/stop_gps_node.sh" &
done < ./slaves
wait