#!/bin/bash -e

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; nodes=4;;
    "cld0") name=cld; nodes=8;;
    "c0") name=c; nodes=16;;
    "cx0") name=cx; nodes=32;;
    "cy0") name=cy; nodes=64;;
    "cz0") name=cz; nodes=128;;
    *) echo "Invalid hostname"; exit -1;;
esac

# dummy command to add master to known hosts
ssh -o StrictHostKeyChecking=no ${name}0 "exit"

for ((i=1;i<=${nodes};i++)); do
    # change hostname without requiring reboot
    ssh -o StrictHostKeyChecking=no ${name}$i "sudo hostname ${name}$i" &
    # change /etc/hostname, so subsequent reboots will have correct hostname
    sudo ssh -o StrictHostKeyChecking=no ${name}$i "echo \"${name}${i}\" > /etc/hostname" &

    sudo scp -o StrictHostKeyChecking=no /etc/hosts ${name}$i:/etc/hosts &
done
wait