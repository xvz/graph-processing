#!/bin/bash -e

# This assigns the proper tags to spot instances after they are launched,
# by using the tags applied to the associated spot instance requests.
# Additionally, this tags the master's EBS volume.
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

machines=$1
source "$(dirname "${BASH_SOURCE[0]}")"/get-hostname.sh


WORKER_IDS=($(aws ec2 describe-spot-instance-requests --filters "Name=state,Values=active" "Name=tag:Name,Values=${name}" \
               | grep "InstanceId" | awk '{print $2}' | sed -e 's/",*//g' | tr '\n' ' '))

aws ec2 create-tags --resources "${WORKER_IDS[@]}" --tags Key=Name,Value=${name}


MASTER_ID=$(aws ec2 describe-spot-instance-requests --filters "Name=state,Values=active" "Name=tag:Name,Values=${name}0" \
             | grep "InstanceId" | awk '{print $2}' | sed -e 's/",*//g')

if [[ ${MASTER_ID} -eq "" ]]; then
    echo "Master spot instance not found... assuming it is on-demand."
else
    aws ec2 create-tags --resources "$MASTER_ID" --tags Key=Name,Value=${name}0

    MASTER_VOL=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=${name}0" \
        | grep "VolumeId" | awk '{print $2}' | sed -e 's/",*//g')
    aws ec2 create-tags --resources "$MASTER_VOL" --tags Key=Name,Value=${name}0
fi