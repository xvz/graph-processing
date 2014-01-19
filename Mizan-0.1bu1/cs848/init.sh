#!/bin/bash -e

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

elif [[ "$hostname" == "cx0" ]]; then
    echo "cx1
cx2
cx3
cx4
cx5
cx6
cx7
cx8
cx9
cx10
cx11
cx12
cx13
cx14
cx15
cx16
cx17
cx18
cx19
cx20
cx21
cx22
cx23
cx24
cx25
cx26
cx27
cx28
cx29
cx30
cx31
cx32" > machines

else
    echo "Invalid hostname"
    exit -1
fi