#!/bin/bash

# NOTE: this is the same as ../master-scripts/start_gps_nodes.sh, but
# is friendlier for automation.
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

source ../conf/gps-env.sh

if [ $# -lt 3 ]; then
    echo "usage: $0 [workers] quick-start [args]"
    exit -1
fi

MASTER_GPS_ID=-1

# required arguments: my-id scripts-directory args
# "args" would be: num-workers quick-start args-to-jar-file
#   (i.e., arguments passed to this file)
../scripts/start_gps_node.sh ${GPS_DIR}/scripts ${MASTER_GPS_ID} "$@" &

# start slaves asynchronously (faster this way)...
i=0

# read-in effectively ensures # of workers never exceeds # of lines in "slaves"
# the "|| ..." is a workaround in case the file doesn't end with a newline
while read slave || [ -n "$slave" ]; do
    ssh $slave "${GPS_DIR}/scripts/start_gps_node.sh ${GPS_DIR}/scripts $i $@" &
    i=$((i+1))
done < ./slaves

# ...and wait until they're all done
wait