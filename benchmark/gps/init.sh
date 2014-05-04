#!/bin/bash -e

# Initiate GPS by creating slaves and machine config files.
#
# NOTE: "slaves" is NOT placed in master-script/, because we use
# our own scripts for starting/stopping GPS workers.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ../common/get-hosts.sh
source ../common/get-dirs.sh
source ../common/get-configs.sh

rm -f slaves
rm -f machine.cfg

# create slaves file
for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    for ((j = 1; j <= ${GPS_WPM}; j++)); do
        echo "${CLUSTER_NAME}${i}" >> slaves
    done
done

# create machine config file
echo "-1 ${HOSTNAME} 64000" >> machine.cfg   # master is special

w_id=0    # worker counter (needed if workers per machine > 1)
for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    # to get multiple workers per machine, use the same name
    # but give it a unique id and port
    for ((j = 1; j <= ${GPS_WPM}; j++)); do
        echo "${w_id} ${CLUSTER_NAME}${i} $((64001 + ${w_id}))" >> machine.cfg
        w_id=$((w_id+1))
    done
done

# upload machine config file to HDFS
hadoop dfsadmin -safemode wait > /dev/null
hadoop dfs -rmr /user/${USER}/gps-machine-config/ || true
hadoop dfs -mkdir /user/${USER}/gps-machine-config/
hadoop dfs -put machine.cfg /user/${USER}/gps-machine-config/

# make GPS log directories if needed
if [[ ! -d "$GPS_LOG_DIR" ]]; then mkdir -p "$GPS_LOG_DIR"; fi
for ((i = 1; i <= ${NUM_MACHINES}; i++)); do
    ssh ${CLUSTER_NAME}${i} "if [[ ! -d \"$GPS_LOG_DIR\" ]]; then mkdir -p \"$GPS_LOG_DIR\"; fi" &
done
wait