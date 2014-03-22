#!/bin/bash -e

# Initiate GPS by creating slaves and machine config files.
#
# NOTE: "slaves" is NOT placed in master-script/, because we
# use our own scripts for starting/stopping GPS nodes.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ../common/get-hosts.sh
source ../common/get-dirs.sh

rm -f slaves
rm -f machine.cfg

# create slaves file
for ((i = 1; i <= ${nodes}; i++)); do
    echo "${name}${i}" >> slaves
done

# create machine config file
for ((i = 0; i <= ${nodes}; i++)); do
    echo "$((-1 + ${i})) ${name}${i} $((55000 + ${i}))" >> machine.cfg
done

# upload machine config file to HDFS
hadoop dfsadmin -safemode wait > /dev/null
hadoop dfs -rmr /user/${USER}/gps-machine-config/ || true
hadoop dfs -mkdir /user/${USER}/gps-machine-config/
hadoop dfs -put machine.cfg /user/${USER}/gps-machine-config/

# make GPS log directories if needed
if [[ ! -d "$GPS_LOGS_DIR" ]]; then mkdir -p "$GPS_LOGS_DIR"; fi
for ((i = 1; i <= ${nodes}; i++)); do
    ssh ${name}${i} "if [[ ! -d \"$GPS_LOGS_DIR\" ]]; then mkdir -p \"$GPS_LOGS_DIR\"; fi" &
done
wait