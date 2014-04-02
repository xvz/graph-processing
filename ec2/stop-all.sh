#!/bin/bash

# Stops all running instances.

ALL_IDS=($(aws ec2 describe-instances | grep "InstanceId" | awk '{print $2}' | sed -e 's/",*//g' | tr '\n' ' '))

aws ec2 stop-instances --instance-ids "${ALL_IDS[@]}"