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
else
    echo "Invalid hostname"
    exit -1
fi

# recompile Mizan
touch ../src/main.cpp
cd ../Release
make all

for((i=1;i<=${nodes};i++)); do
  scp ../Release/Mizan-0.1b ${name}$i:~/Mizan-0.1bu1/Release/
done

echo "OK."