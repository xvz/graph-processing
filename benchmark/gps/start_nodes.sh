#!/bin/bash -e

# Basically master-scripts/start_gps_nodes.sh made friendlier for automation.
# This also eliminates the need of having scripts/start_gps_node.sh at every worker.
#
# To change max JVM heap size for GPS workers, change XMX_SIZE below.
#
# To use this, pass in arguments like:
#
#./start_nodes.sh ${nodes} quick-start \
#    -ifs /user/ubuntu/input/${inputgraph} \
#    -hcf /home/ubuntu/hadoop-1.0.4/conf/core-site.xml \
#    -jc gps.examples.pagerank.PageRankVertex###JobConfiguration \
#    -mcfg /user/ubuntu/gps-machine-config/cs848.cfg \
#    -log4jconfig /home/ubuntu/gps-rev-110/conf/log4j.config \
#    -other -max###30
#
# Note that GPS's default start script requires 3rd argument
# and onwards to be double-quoted, i.e.:
#
#../master-scripts/start_gps_nodes.sh ${nodes} quick-start \
#    "-ifs /user/ubuntu/input/${inputgraph} \
#    -hcf /home/ubuntu/hadoop-1.0.4/conf/core-site.xml \
#    -jc gps.examples.pagerank.PageRankVertex###JobConfiguration \
#    -mcfg /user/ubuntu/gps-machine-config/cs848.cfg \
#    -log4jconfig /home/ubuntu/gps-rev-110/conf/log4j.config \
#    -other -max###30"
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
# Extra note: one way to get automation when using the original gps_start_nodes.sh
# is by modifying the last slave's start_gps_node.sh to not have the "&". That way,
# since slaves are started sequentially, the last one will return only when the
# computation is complete.

if [ $# -lt 3 ]; then
    echo "usage: $0 [workers] quick-start [gps-args]"
    exit -1
fi

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-dirs.sh


## start master
MASTER_GPS_ID=-1
MASTER_XMS_SIZE=50M     # initial heap size (master)
MASTER_XMX_SIZE=2048M   # max heap size (master)

echo "Starting GPS master -1"
"$JAVA_DIR"/bin/java -Xincgc -Xms${MASTER_XMS_SIZE} -Xmx${MASTER_XMX_SIZE} -verbose:gc -jar "$GPS_DIR"/gps_node_runner.jar -machineid ${MASTER_PS_ID} -ofp /user/ubuntu/gps-output/${2}-machine-stats ${@:3} &> "$GPS_LOGS"/${2}-machine${i}-output.txt &


## start slaves asynchronously (faster this way)
XMS_SIZE=256M   # initial heap size (workers)
XMX_SIZE=3500M  # max heap size (workers)

# read-in effectively ensures # of workers never exceeds # of lines in "slaves"
# the "|| ..." is a workaround in case the file doesn't end with a newline
i=0
while read slave || [ -n "$slave" ]; do
    echo "Starting GPS worker ${i}"

    OUTPUT_FILE_NAME=${2}-output-${i}-of-${1}
    ssh $slave "\"$JAVA_DIR\"/bin/java -Xincgc -Xms${XMS_SIZE} -Xmx${XMX_SIZE} -verbose:gc -jar \"$GPS_DIR\"/gps_node_runner.jar -machineid ${i} -ofp /user/ubuntu/gps-output/${OUTPUT_FILE_NAME} ${@:3} &> \"$GPS_LOGS\"/${2}-machine${i}-output.txt" &

    ((i++))
done < ./slaves

# ...and wait until computation completes
wait