#!/bin/bash

# A modified version of master-scripts/start_gps_nodes.sh made friendlier
# for automation. This incorporates scripts/start_gps_node.sh, so workers
# no longer need to be updated with that script. HDFS output paths,
# log paths, etc. remain unchanged.
#
# Slaves are started asynchronously, which is faster. This script (i.e.,
# the master) waits until all slaves are done computations before exiting,
# making it either to script benchmarks.
#
# The number of workers MUST match the number of machines specified
# in BOTH the slaves and machine config file. # of workers argument is
# only used in naming the output files. It is otherwise IGNORED:
#
#  >> If # workers < # specified machines, we start # of specified machines.
#     (Otherwise, GPS would hang waiting for the extra workers).
#  >> If # workers > # specified machines, we start # of specified machines.
#
# To change max JVM heap size for GPS workers, change XMX_SIZE below.

MASTER_XMX_SIZE=2048M   # max heap size (master)
XMX_SIZE=7000M          # max heap size (workers)


# To use this, pass in arguments like:
#
#./start-nodes.sh ${nodes} quick-start \
#    -ifs /user/${USER}/input/${inputgraph} \
#    -hcf "$HADOOP_DIR"/conf/core-site.xml \
#    -jc gps.examples.pagerank.PageRankVertex###JobConfiguration \
#    -mcfg /user/${USER}/gps-machine-config/cs848.cfg \
#    -log4jconfig "$GPS_DIR"/conf/log4j.config \
#    -other -max###30
#
# Note that GPS's default start script requires 3rd argument
# and onwards to be double-quoted, i.e.:
#
#./master-scripts/start_gps_nodes.sh ${nodes} quick-start \
#    "-ifs /user/${USER}/input/${inputgraph} \
#     -hcf \"$HADOOP_DIR\"/conf/core-site.xml \
#     -jc gps.examples.pagerank.PageRankVertex###JobConfiguration \
#     -mcfg /user/${USER}/gps-machine-config/cs848.cfg \
#     -log4jconfig \"$GPS_DIR\"/conf/log4j.config \
#     -other -max###30"
#
#
# To start multiple workers per machine, modify the slaves file to be, e.g.
#
# cloud1
# cloud1
# cloud2
# cloud2
#
# and similarly for the machine config file.
#
#
# Side note: one way to get automation when using the original gps_start_nodes.sh
# is by modifying the last slave's start_gps_node.sh to not have the "&". That way,
# since slaves are started sequentially, the last one will return only when the
# computation is complete.

if [ $# -lt 3 ]; then
    echo "usage: $0 workers mode gps-args"
    echo ""
    echo "mode: use 'quick-start' (without quotes)"
    echo "gps-args: arguments passed to GPS jar, unquoted"
    exit -1
fi

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-dirs.sh


OUTPUT_DIR=/user/${USER}/gps/output/

## start master
MASTER_GPS_ID=-1
MASTER_XMS_SIZE=50M     # initial heap size (master)

echo "Starting GPS master -1"
"$JAVA_DIR"/bin/java -Xincgc -Xms${MASTER_XMS_SIZE} -Xmx${MASTER_XMX_SIZE} -verbose:gc -jar "$GPS_DIR"/gps_node_runner.jar -machineid ${MASTER_GPS_ID} -ofp "$OUTPUT_DIR"/${2}-machine-stats ${@:3} &> "$GPS_LOGS_DIR"/${2}-machine${i}-output.txt &

## start slaves asynchronously (faster this way)
XMS_SIZE=256M   # initial heap size (workers)

# read-in effectively ensures # of workers never exceeds # of lines in "slaves"
# the "|| ..." is a workaround in case the file doesn't end with a newline
i=0
while read slave || [ -n "$slave" ]; do
    echo "Starting GPS worker ${i}"

    ssh $slave "\"$JAVA_DIR\"/bin/java -Xincgc -Xms${XMS_SIZE} -Xmx${XMX_SIZE} -verbose:gc -jar \"$GPS_DIR\"/gps_node_runner.jar -machineid ${i} -ofp \"$OUTPUT_DIR\"/${2}-output-${i}-of-$((${1}-1)) ${@:3} &> \"$GPS_LOGS_DIR\"/${2}-machine${i}-output.txt" &

    ((i++))
    # no need to check if # workers < # slaves... GPS will hang in that situation
done < "$(dirname "${BASH_SOURCE[0]}")"/slaves

# ...and wait until computation completes
# NOTE: this script must not have -e, else it will fail while launching slaves
wait
echo "Computation complete!"