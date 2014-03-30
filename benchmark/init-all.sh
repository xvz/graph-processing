#!/bin/bash -e

# Initialize Hadoop and all systems.
#
# NOTE: before doing this, ensure the master has:
#   1. A correct hostname (use "sudo hostname X" to update it without reboot)
#   2. A correct hostname in /etc/hostname
#   3. Correct IPs and names of all workers in /etc/hosts
#   4. Correct JVM Xmx size set for Giraph (see ./hadoop/init.sh)
#   5. Correct JVM Xmx size set for GPS (see ./gps/start-nodes.sh)
#
# See ./common/get-hosts.sh for the expected naming formats and prefixes.

read -p "Press enter to continue..."

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./common/get-hosts.sh
source ./common/get-dirs.sh


# update workers' hostnames
echo "Updating worker hosts..."
./common/update-hosts.sh

echo "Updating Hadoop configs..."
./hadoop/init.sh

###############
# Hadoop
###############
# remove old HDFS data (on master and workers)
# NOTE: removing HDFS folder will kill targets of symlinks in logs/userlogs/
echo "Removing old HDFS data and Hadoop logs..."

stop-all.sh > /dev/null   # just in case anything is running

# do it separately for the master---this is useful when testing on a single machine
rm -rf "$HADOOP_DATA_DIR"; rm -rf "$HADOOP_DIR"/logs/*
for ((i = 1; i <= ${nodes}; i++)); do
    ssh ${name}${i} "rm -rf \"$HADOOP_DATA_DIR\"; rm -rf \"$HADOOP_DIR\"/logs/*" &
done
wait

# create new HDFS & start Hadoop
echo "Creating new HDFS..."
hadoop namenode -format
start-all.sh

# wait until Hadoop starts up (HDFS exits safemode)
echo "Waiting for Hadoop to start..."
hadoop dfsadmin -safemode wait > /dev/null


###############
# Systems
###############
# nothing to do for Giraph

echo "Initializing GPS..."
./gps/init.sh

echo "Initializing GraphLab..."
./graphlab/init.sh

echo "Initializing Mizan..."
./mizan/init.sh


###############
# Datasets
###############
#echo "Loading datasets..."
#./datasets/load-files.sh