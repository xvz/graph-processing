#!/bin/bash

if [ $# -ne 3 ]; then
    echo "usage: $0 [workers] [??] [args]"
    exit -1
fi
# same as ../master-scripts/start_gps_nodes.sh, but with no safety checks

MASTER_GPS_ID=-1
../scripts/start_gps_node.sh ${GPS_DIR}/scripts ${MASTER_GPS_ID} ${1} ${2} "${3}"

while read slave; do
    ssh $slave "$PWD/../scripts/start_gps_node.sh $1 $2 $3" &
done < ./slaves
wait