#!/bin/bash

# Runs all the benchmarks. If something fails, it will
# just continue to the next experiment.
#
# The mass-benchmarking scripts are quite primitive,
# simply because things can and will fail and it's
# usually easier to intervene manually.

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