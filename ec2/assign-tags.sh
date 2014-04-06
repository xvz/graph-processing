#!/bin/bash -e

# This assigns the proper tags to spot instances after they are launched,
# by using the tags applied to the associated spot instance requests.
#
# By default, only spot instance *requests* are tagged---the resulting
# launched instances remain untagged.
#
# The spot instance requests MUST be correctly tagged for this to work.

if [ $# -lt 1 ]; then
    echo "usage: $0 machines"
    echo ""
    echo "machines: 4, 8, 16, 32, 64, or 128"
    exit -1
fi

NUM_MACHINES=$1

case ${NUM_MACHINES} in
    4)   name=cloud; machines=4;;
    8)   name=cld; machines=8;;
    16)  name=cw; machines=16;;
    32)  name=cx; machines=32;;
    64)  name=cy; machines=64;;
    128) name=cz; machines=128;;
    *) echo "Invalid option!"; exit -1;;
esac

MASTER_ID=($(aws ec2 describe-spot-instance-requests --filter "Name=tag:Name,Values=${name}0" \
               | grep "InstanceId" | awk '{print $2}' | sed -e 's/",*//g' | tr '\n' ' '))
WORKER_IDS=($(aws ec2 describe-spot-instance-requests --filter "Name=tag:Name,Values=${name}" \
               | grep "InstanceId" | awk '{print $2}' | sed -e 's/",*//g' | tr '\n' ' '))

aws ec2 create-tags --resources "${MASTER_ID}" --tags Key=Name,Value=${name}0
aws ec2 create-tags --resources "${WORKER_IDS[@]}" --tags Key=Name,Value=${name}
