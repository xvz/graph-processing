#!/bin/bash -e

# Terminates worker instances. This deletes its EBS volume. Use with care!!
# This will not stop or terminate the master (provided it's tagged correctly).

echo "Terminate workers of:"
echo "  1) cloud0 (4)"
echo "  2) cld0 (8)"
echo "  3) cw0 (16)"
echo "  4) cx0 (32)"
echo "  5) cy0 (64)"
echo "  6) cz0 (128)"

read -p ">> " response

case ${response} in
    1) name=cloud; nodes=4;;
    2) name=cld; nodes=8;;
    3) name=cw; nodes=16;;
    4) name=cx; nodes=32;;
    5) name=cy; nodes=64;;
    6) name=cz; nodes=128;;
    *) echo "Invalid option!"; exit -1;;
esac


WORKER_IDS=($(aws ec2 describe-instances --filter "Name=tag:Name,Values=${name}" \
               | grep "InstanceId" | awk '{print $2}' | sed -e 's/",*//g' | tr '\n' ' '))

aws ec2 terminate-instances --instance-ids "${WORKER_IDS[@]}"