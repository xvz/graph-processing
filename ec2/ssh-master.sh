#!/bin/bash -e

# Connects to the master via ssh.
#
# NOTE: Master must be tagged with the name "cw0" or "cx0", etc.

echo "Connect to:"
echo "  1) cloud0 (4)"
echo "  2) cld0 (8)"
echo "  3) cw0 (16)"
echo "  4) cx0 (32)"
echo "  5) cy0 (64)"
echo "  6) cz0 (128)"

read -p ">> " response

case ${response} in
    1) name=cloud; machines=4;;
    2) name=cld; machines=8;;
    3) name=cw; machines=16;;
    4) name=cx; machines=32;;
    5) name=cy; machines=64;;
    6) name=cz; machines=128;;
    *) echo "Invalid option!"; exit -1;;
esac

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./get-pem.sh

MASTER_IP=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=${name}0" \
             | grep 'PublicIpAddress\":' | awk '{print $2}' | sed -e 's/",*//g')

# use ec2-user (instead of ubuntu) for instances running non-Ubuntu images
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$PEM_KEY" ubuntu@${MASTER_IP}