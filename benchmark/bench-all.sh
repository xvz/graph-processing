#!/bin/bash

# Runs all the benchmarks.
#
# The batch-benchmarking scripts are quite primitive, simply because
# when things fail it's usually easier to intervene manually.
#
# We recommend running this in a "screen" so a terminated ssh
# connection doesn't kill it.
#
# Use "screen" to start a screen and run "./bench-all.sh" within it.
# Detach from the screen at any time with C-a d (Ctrl-a d).
# Reattach to the screen anywhere with "screen -R". This can be done
# after a detach or when ssh is inadvertently killed.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./common/get-hosts.sh
source ./common/get-dirs.sh

# start (or restart) Hadoop
./hadoop/restart-hadoop.sh
hadoop dfsadmin -safemode wait > /dev/null

echo "Running Giraph experiments..."
./giraph/benchall.sh ${NUM_MACHINES} 5

echo "Running GPS experiments..."
./gps/benchall.sh ${NUM_MACHINES} 5

echo "Running GraphLab experiments..."
./graphlab/benchall.sh ${NUM_MACHINES} 5

echo "Running Mizan experiments..."
./mizan/benchall.sh ${NUM_MACHINES} 5