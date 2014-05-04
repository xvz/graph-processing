#!/bin/bash -e

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-hosts.sh
source "$commondir"/get-dirs.sh

cd "$GPS_DIR/local-master-scripts/"
./make_gps_node_runner_jar.sh

for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    scp ../gps_node_runner.jar ${CLUSTER_NAME}${i}:"$GPS_DIR"/gps_node_runner.jar &
done
wait

echo "OK."