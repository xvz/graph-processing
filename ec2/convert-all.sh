#!/bin/bash

# Converts all existing instances to one instance type (m3.large).

ALL_IDS=($(aws ec2 describe-instances | grep "InstanceId" | awk '{print $2}' | sed -e 's/",*//g' | tr '\n' ' '))

aws ec2 modify-instance-attribute --instance-id "${ALL_IDS[@]}" --instance-type m1.xlarge