#!/bin/bash -e

source ../conf/gps-env.sh

# the "|| ..." is a workaround in case the file doesn't end with a newline
while read slave || [ -n "$slave" ]; do
    scp ../scripts/start_gps_node.sh $slave:${GPS_DIR}/scripts/ &
    scp ../scripts/stop_gps_node.sh $slave:${GPS_DIR}/scripts/ &
done < ./slaves
wait