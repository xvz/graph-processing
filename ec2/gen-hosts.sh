#!/bin/bash -e

# Obtains the private IP addresses for the /etc/hosts file.
#
# NOTE: This expects the master to be tagged with the name
# "cw0" or "cx0", etc. and the workers to be ALL tagged with
# the name "cw" or "cx", etc.
#
# If workers are spot instances, ensure the actual instances
# are tagged correctly (by, e.g., using ./assign-tags.sh)

if [ $# -lt 1 ]; then
    echo "usage: $0 workers"
    echo ""
    echo "workers: 4, 8, 16, 32, 64, or 128"
    exit -1
fi

WORKERS=$1

case ${WORKERS} in
    4)   name=cloud; nodes=4;;
    8)   name=cld; nodes=8;;
    16)  name=cw; nodes=16;;
    32)  name=cx; nodes=32;;
    64)  name=cy; nodes=64;;
    128) name=cz; nodes=128;;
    *) echo "Invalid option!"; exit -1;;
esac

####################
# Get private IPs
####################
# master is special, so filter it separately
MASTER_IP=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=${name}0" \
             | grep 'PrivateIpAddress\":' | awk '{print $2}' | sed -e 's/",*//g' | uniq)

# filter only for workers (skipping the master)
WORKER_IPS=($(aws ec2 describe-instances --filter "Name=tag:Name,Values=${name}" \
               | grep 'PrivateIpAddress\":' | awk '{print $2}' | sed -e 's/",*//g' \
               | uniq | sort -t . -nk1,1 -nk2,2 -nk3,3 -nk4,4))

####################
# Output /etc/hosts
####################
echo "${MASTER_IP} ${name}0" 

# output data for /etc/hosts file
for i in "${!WORKER_IPS[@]}"; do
    echo "${WORKER_IPS[$i]} ${name}$((i+1))"
done