#!/bin/bash -e

# Updates workers' /etc/hostname and /etc/hosts files and adds them to known_hosts.
#
# NOTE: Name changes take effect immediately---there is no need to reboot.

source "$(dirname "${BASH_SOURCE[0]}")"/get-hosts.sh

# dummy command to add master to known hosts
ssh -o StrictHostKeyChecking=no $hostname "exit"

for ((i = 1; i <= ${nodes}; i++)); do
    # change hostname without requiring reboot
    ssh -o StrictHostKeyChecking=no ${name}${i} "sudo hostname ${name}${i}" &

    # change /etc/hostname, so subsequent reboots will have correct hostname
    sudo ssh -o StrictHostKeyChecking=no ${name}${i} "echo \"${name}${i}\" > /etc/hostname" &
    sudo scp -o StrictHostKeyChecking=no /etc/hosts ${name}${i}:/etc/hosts &
done
wait