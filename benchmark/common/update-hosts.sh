#!/bin/bash -e

# Updates workers' /etc/hostname and /etc/hosts files and adds them to known_hosts.
# Name changes take effect immediately---there is no need to reboot.
#
# NOTE: Ignore "unable to resolve host" messages (it's not an error)

source "$(dirname "${BASH_SOURCE[0]}")"/get-hosts.sh

# dummy command to add master to known_hosts
ssh -o StrictHostKeyChecking=no $hostname "exit"

for ((i = 1; i <= ${nodes}; i++)); do
    # update /etc/hosts
    scp -o StrictHostKeyChecking=no /etc/hosts ${name}${i}:/tmp/hosts && \
    ssh -o StrictHostKeyChecking=no ${name}${i} "sudo mv /tmp/hosts /etc/hosts" &

    # update /etc/hostname & change hostname without reboot
    ssh -o StrictHostKeyChecking=no ${name}${i} \
        "echo \"${name}${i}\" > /tmp/hostname && sudo mv /tmp/hostname /etc/hostname; sudo hostname ${name}${i}" &
done
wait