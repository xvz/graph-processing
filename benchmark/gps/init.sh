#!/bin/bash -e

read -p "Enter to continue..." none

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; nodes=4;;
    "cld0") name=cld; nodes=8;;
    "c0") name=c; nodes=16;;
    "cx0") name=cx; nodes=32;;
    "cy0") name=cy; nodes=64;;
    "cz0") name=cz; nodes=128;;
    *) echo "Invalid hostname"; exit -1;;
esac

rm -f slaves
rm -f cs848.cfg

# create slaves file
# NOTE: this is NOT placed in master-script/slaves, b/c we
# are using our own scripts for starting/stopping GPS nodes
for ((i = 1; i <= ${nodes}; i++)); do
    echo "${name}${i}" >> slaves
done

# create machine config file
for ((i = 0; i <= ${nodes}; i++)); do
    echo "$((-1 + ${i})) ${name}${i} $((55000 + ${i}))" >> cs848.cfg
done

# upload machine config file to HDFS
hadoop dfs -mkdir /user/ubuntu/gps-machine-config/
hadoop dfs -put cs848.cfg /user/ubuntu/gps-machine-config/

# make tmp directory, where gps outputs logs
mkdir ~/var/tmp