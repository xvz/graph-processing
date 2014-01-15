#!/bin/bash

read -p "Any key to continue..." none

hostname=$(hostname)

if [[ "$hostname" == "cloud0" ]]; then
    echo "cloud1
cloud2
cloud3
cloud4" > machines

elif [[ "$hostname" == "cld0" ]]; then
    echo "cld1
cld2
cld3
cld4
cld5
cld6
cld7
cld8" > machines

elif [[ "$hostname" == "c0" ]]; then
    echo "c1
c2
c3
c4
c5
c6
c7
c8
c9
c10
c11
c12
c13
c14
c15
c16" > machines

else
    echo "Invalid hostname"
    exit
fi