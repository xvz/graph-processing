#!/bin/bash -e

# Obtains private IP addresses of all worker machines, creates
# a hosts file and updates the master with a correct hostname,
# /etc/hostname, and /etc/hosts file.
#
# NOTE: This expects the master to be tagged with the name
# "cw0" or "cx0", etc. and the worker machines to be ALL tagged
# with the name "cw" or "cx", etc.
#
# If any machines are spot instances, ensure actual instances
# are tagged correctly (by, e.g., using ./assign-tags.sh)

if [ $# -lt 1 ]; then
    echo "usage: $0 machines"
    echo ""
    echo "machines: 4, 8, 16, 32, 64, or 128"
    exit -1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

machines=$1
source ./get-hostname.sh
source ./get-pem.sh


####################
# Get private IPs
####################
# master is special, so filter it separately
MASTER_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${name}0" \
             | grep 'PrivateIpAddress\":' | awk '{print $2}' | sed -e 's/",*//g' | uniq)

# filter only for worker machines (skipping the master)
WORKER_IPS=($(aws ec2 describe-instances --filters "Name=tag:Name,Values=${name}" \
               | grep 'PrivateIpAddress\":' | awk '{print $2}' | sed -e 's/",*//g' \
               | uniq | sort -t . -nk1,1 -nk2,2 -nk3,3 -nk4,4))


####################
# Output /etc/hosts
####################
# this bit is in /etc/hosts by default
echo "127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
" > hosts_${machines}

# this stuff is what we care about
echo "${MASTER_IP} ${name}0" | tee -a hosts_${machines}

for i in "${!WORKER_IPS[@]}"; do
    echo "${WORKER_IPS[$i]} ${name}$((i+1))" | tee -a hosts_${machines}
done


####################
# Update master
####################
MASTER_PUBIP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${name}0" \
                | grep 'PublicIpAddress\":' | awk '{print $2}' | sed -e 's/",*//g')

echo ""
echo "Copying /etc/hosts to master..."
# update /etc/hosts (a bit hacky as scp doesn't have sudo)
scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$PEM_KEY" ./hosts_${machines} ubuntu@${MASTER_PUBIP}:/tmp/hosts && \
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$PEM_KEY" ubuntu@${MASTER_PUBIP} "sudo mv /tmp/hosts /etc/hosts"

echo "Updating hostname..."
# update /etc/hostname & change hostname without reboot
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "$PEM_KEY" -t ubuntu@${MASTER_PUBIP} \
    "echo \"${name}0\" > /tmp/hostname && sudo mv /tmp/hostname /etc/hostname; sudo hostname ${name}0"

rm -f hosts_${machines}

echo ""
echo "OK. (Ignore 'unable to resolve host' messages)"