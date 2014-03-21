#!/bin/bash

source ../conf/gps-env.sh

# does the same thing as ../master-scripts/stop_gps_nodes.sh but faster
../scripts/stop_gps_node.sh

# the "|| ..." is a workaround in case the file doesn't end with a newline
while read slave || [ -n "$slave" ]; do
    ssh $slave "${GPS_DIR}/scripts/stop_gps_node.sh" &
done < ./slaves
wait