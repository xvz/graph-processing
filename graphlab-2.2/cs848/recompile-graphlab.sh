#!/bin/bash -e

hostname=$(hostname)

if [[ "$hostname" == "cloud0" ]]; then
    name=cloud
    nodes=4
elif [[ "$hostname" == "cld0" ]]; then
    name=cld
    nodes=8
elif [[ "$hostname" == "c0" ]]; then
    name=c
    nodes=16
elif [[ "$hostname" == "cx0" ]]; then
    name=cx
    nodes=32
else
    echo "Invalid hostname"
    exit -1
fi

# recompile GraphLab
# todo...

for((i=1;i<=${nodes};i++)); do
    # rsync is smart, won't copy unchanged files
    rsync -az --exclude '*.make' --exclude '*.cmake' ~/graphlab-2.2/release/toolkits/ ${name}$i:~/graphlab-2.2/release/toolkits
    rsync -az --exclude '*.make' --exclude '*.cmake' ~/graphlab-2.2/deps/local/ ${name}$i:~/graphlab-2.2/deps/local
done

echo "OK."