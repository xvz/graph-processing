#!/bin/bash -e

if [ $# -ne 2 ]; then
    echo "usage: $0 [input graph] [ec2 nodes]"
    exit -1
fi

# place input in /user/ubuntu/gps-input/
# output is in /user/ubuntu/gps/output/
inputgraph=$(basename $1)

# nodes should be number of EC2 instances
nodes=$2

logname=mst_${inputgraph}_${nodes}_"$(date +%F-%H-%M-%S)"
logfile=${logname}.txt       # GPS statistics (incl running time)

## start logging memory + network usage
./bench_init.sh ${logname}

## start algorithm run
cd ../master-scripts/

# there are 3 versions of MST... according to author, these are:
#
# edgesatrootpjonebyone uses standard Boruvka (no optimizations)
# edgesatselfpjonebyone uses "storing edges at subvertices" (SEAS)
#   -> "edge cleaning on demand" (ECOD) is enabled via flag
# edgeshybridpjonebyone uses SEAS for few iteratins then default... but not published
./start_gps_nodes.sh ${nodes} quick-start "-ifs /user/ubuntu/gps-input/${inputgraph} -hcf /home/ubuntu/hadoop-1.0.4/conf/core-site.xml -jc gps.examples.mst.edgesatrootpjonebyone.JobConfiguration -mcfg /user/ubuntu/gps-machine-config/cs848.cfg -log4jconfig /home/ubuntu/gps-rev-110/conf/log4j.config"

## finish logging memory + network usage
cd ../cs848/
./bench_finish.sh ${logname}

## get stats (see debug_site.sh for debug naming convention)
hadoop dfs -get /user/ubuntu/gps/output/quick-start-machine-stats ./${logfile}
hadoop dfs -mv /user/ubuntu/gps/output/quick-start-machine-stats /user/ubuntu/gps/stats-${logname}

# sleep a bit, to prevent next run from failing
#sleep 30