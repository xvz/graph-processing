#!/bin/bash -e

# Initialize Hadoop and all systems.
#
# NOTE: before doing this, ensure:
#   1. All machines have correct hostnames, /etc/hostname, and /etc/hosts
#   2. Master has correct JVM Xmx size set for Giraph and GPS
#
# For (1), see ../ec2/uw-ec2.py init
# For (2), see ./common/get-config.sh
#
# To check connectivity, use ./common/ssh-check.sh

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./common/get-hosts.sh
source ./common/get-dirs.sh

# remove known_hosts (kills stale fingerprints)
echo "Removing known_hosts..."
rm -f ~/.ssh/known_hosts

echo "Creating known_hosts..."
for ((i = 0; i <= ${machines}; i++)); do
    ssh -q -o StrictHostKeyChecking=no ${name}${i} "exit" &
done
wait

echo "Updating Hadoop configs..."
./hadoop/init.sh > /dev/null      # quiet


###############
# Hadoop
###############
# remove old HDFS data (on master and worker machines)
# NOTE: removing HDFS folder will kill targets of symlinks in logs/userlogs/
echo "Removing old HDFS data and Hadoop logs..."

stop-all.sh > /dev/null   # just in case anything is running

for ((i = 0; i <= ${machines}; i++)); do
    ssh ${name}${i} "rm -rf \"$HADOOP_DATA_DIR\"; rm -rf \"$HADOOP_DIR\"/logs/*" &
done
wait

# create new HDFS & start Hadoop
echo "Creating new HDFS..."
hadoop namenode -format

echo "Starting up Hadoop..."
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
hadoop dfs -mkdir ./input || true
#echo "Loading datasets..."
#./datasets/load-files.sh