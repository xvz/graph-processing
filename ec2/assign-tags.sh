#!/bin/bash -e

# This assigns the proper tags to spot instances after they are launched,
# by using the tags applied to the associated spot instance requests.
#
# By default, only spot instance *requests* are tagged---the resulting
# launched instances remain untagged.
#
# The spot instance requests MUST be correctly tagged for this to work.

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


WORKER_IDS=($(aws ec2 describe-spot-instance-requests --filter "Name=tag:Name,Values=${name}" \
               | grep "InstanceId" | awk '{print $2}' | sed -e 's/",*//g' | tr '\n' ' '))

aws ec2 create-tags --resources "${WORKER_IDS[@]}" --tags Key=Name,Value=${name}