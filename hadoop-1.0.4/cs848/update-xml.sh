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

cd ~/hadoop-1.0.4/conf/

for ((i=1;i<=${nodes};i++)); do
    rsync -e "ssh -o StrictHostKeyChecking=no" -avz ./* ${name}$i:~/hadoop-1.0.4/conf/ &
done
wait