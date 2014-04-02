#!/bin/bash

# Runs all the benchmarks. If something fails, it will
# just continue to the next experiment.
#
# The batch-benchmarking scripts are quite primitive, simply because
# when things fail it's usually easier to intervene manually.
#
#
# We recommend running this with disown or nohup, so that a broken
# ssh connection doesn't kill the job. For example:
# ./bench-all.sh &      (this should output "[X] ####"---X is usually 1)
# disown -h %X          (where X is from above)
#
# Note: disown -h allows the task to be brought back to fg in the
# same shell session, but be aware that this *will* kill the task if
# the ssh connection cuts out!

read -p "Press enter to continue..."

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./common/get-hosts.sh
source ./common/get-dirs.sh

# start (or restart) Hadoop
./hadoop/restart-hadoop.sh
hadoop dfsadmin -safemode wait > /dev/null

echo "Running Giraph experiments..."
./giraph/benchall.sh ${nodes} 5

echo "Running GPS experiments..."
./gps/benchall.sh ${nodes} 5

echo "Running GraphLab experiments..."
./graphlab/benchall.sh ${nodes} 5

echo "Running Mizan experiments..."
./mizan/benchall.sh ${nodes} 5