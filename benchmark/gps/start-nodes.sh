#!/bin/bash -e

# A modified version of master-scripts/start_gps_nodes.sh made friendlier
# for automation. This incorporates scripts/start_gps_node.sh, so worker
# machines no longer need to be updated with that script. HDFS output paths,
# log paths, etc. remain unchanged.
#
# Note that each machine can have *multiple* workers. Hence, we refer to
# physical machines as "machines" and workers as "workers" or "slaves".
#
# Workers are started asynchronously, which is faster. This script (i.e.,
# the master) waits until all workers are done computations before exiting,
# making it either to script benchmarks. (Although a sleep delay is still
# required---see the batch benching scripts.)
#
# Because of how GPS behaves, the # of workers argument is actually IGNORED.
# Instead, we use # of workers specified in machine slaves/config file.
# Specifically:
#
#  >> If argument < # of actual workers, we start # of actual workers.
#     (Otherwise, GPS will hang waiting for the extra workers)
#  >> If argument > # of actual workers, we start # of actual workers.
#     (Because no ports are specified for extra non-existent workers)
#

#
# To change max JVM heap size for GPS workers, see ../common/get-configs.sh.
#

# To use this, pass in arguments like:
#
#./start-nodes.sh ${workers} quick-start \
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
#./master-scripts/start_gps_nodes.sh ${workers} quick-start \
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

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-dirs.sh
source "$commondir"/get-configs.sh


OUTPUT_DIR=/user/${USER}/gps/output/

## start master
MASTER_GPS_ID=-1
GPS_MASTER_XMS=50M     # initial heap size (master)

echo "Using args: ${@:3}"

echo "Starting GPS master -1"
"$JAVA_DIR"/bin/java -Xincgc -Xms${GPS_MASTER_XMS} -Xmx${GPS_MASTER_XMX} -verbose:gc -jar "$GPS_DIR"/gps_node_runner.jar -machineid ${MASTER_GPS_ID} -ofp "$OUTPUT_DIR"/${2}-machine-stats ${@:3} &> "$GPS_LOG_DIR"/${2}-machine${i}-output.txt &

## start slaves asynchronously (faster this way)
GPS_WORKER_XMS=256M   # initial heap size (workers)

# read-in effectively ensures # of workers never exceeds # of lines in "slaves"
# the "|| ..." is a workaround in case the file doesn't end with a newline
w_id=0
while read slave || [ -n "$slave" ]; do
    echo "Starting GPS worker ${w_id}"

    # must have -n, otherwise ssh consumes all of stdin (i.e., all of the input file)
    # outer & runs ssh in the background
    # inner & and stdout/err redirections enable ssh connection to end while remote command continues to run
    ssh -n $slave "\"$JAVA_DIR\"/bin/java -Xincgc -Xms${GPS_WORKER_XMS} -Xmx${GPS_WORKER_XMX} -verbose:gc -jar \"$GPS_DIR\"/gps_node_runner.jar -machineid ${w_id} -ofp \"$OUTPUT_DIR\"/${2}-output-${w_id}-of-$((${1}-1)) ${@:3} &> \"$GPS_LOG_DIR\"/${2}-machine${w_id}-output.txt &" &

    w_id=$((w_id+1))
    # no need to check if # workers < # slaves... GPS will hang in that situation
done < "$(dirname "${BASH_SOURCE[0]}")"/slaves

# ...and wait until computation completes (= master finishes)
wait
echo "Computation complete!"