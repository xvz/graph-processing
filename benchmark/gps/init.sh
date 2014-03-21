#!/bin/bash -e

# Initiate GPS by creating slaves and machine config files.
#
# NOTE: "slaves" is NOT placed in master-script/, because we
# use our own scripts for starting/stopping GPS nodes.

read -p "Enter to continue..." none

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-hosts.sh
source "$commondir"/get-dirs.sh

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
hadoop dfs -mkdir /user/ubuntu/gps-machine-config/
hadoop dfs -put machine.cfg /user/ubuntu/gps-machine-config/

# make tmp directory, where GPS outputs logs
mkdir "$GPS_LOGS"