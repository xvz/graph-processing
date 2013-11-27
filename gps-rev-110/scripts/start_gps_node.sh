#!/bin/bash

# arg 1 is the directory of the script
# arg 2 is the worker id number (starts from 0)
# arg 3 is the number of slaves (max worker id = slaves-1)
# arg 4 is the mode (ie, examples use quickstart)
# arg 5 is the extra paramters (-ifs, -hcf, etc.) 

source $1/../conf/gps-env.sh

cd $GPS_DIR
echo "1: $1"
echo "2: $2"
echo "3: $3"
echo "4: $4"

echo `whoami`
if [ $# -lt 4 ]
then
    echo "You have to give at least the worker-id TODO(semih): complete"
    echo ""
    exit
fi

echo "starting gps worker ${2}"
# Set the XMS_SIZE and XMX_SIZE properties according to the RAM in the machines of your cluster.
XMS_SIZE=256M   # initial heap size
XMX_SIZE=2048M  # max heap size
OUTPUT_FILE_NAME=${4}-output-${2}-of-${3}
if [ ${2} -eq -1 ]; then
    XMS_SIZE=50M
    XMX_SIZE=50M
    OUTPUT_FILE_NAME=${4}-machine-stats
fi

echo "-Xincgc -Xms$XMS_SIZE -Xmx$XMX_SIZE"

/home/ubuntu/jdk1.6.0_30/bin/java -Xincgc -Xms${XMS_SIZE} -Xmx${XMX_SIZE} -verbose:gc -jar ${GPS_DIR}/gps_node_runner.jar -machineid ${2} -ofp /user/${USER}/gps/output/${OUTPUT_FILE_NAME} ${5} &> ${GPS_LOG_DIRECTORY}/${4}-machine${2}-output.txt &
