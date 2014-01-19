#!/bin/bash -e

read -p "Any key to continue..." none

cd ~/hadoop-1.0.4/conf/

hostname=$(hostname)

if [[ "$hostname" == "cloud0" ]]; then
    echo "cloud0" > masters

    echo "cloud1
cloud2
cloud3
cloud4" > slaves

elif [[ "$hostname" == "cld0" ]]; then
    echo "cld0" > masters

    echo "cld1
cld2
cld3
cld4
cld5
cld6
cld7
cld8" > slaves

elif [[ "$hostname" == "c0" ]]; then
    echo "c0" > masters

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
c16" > slaves

elif [[ "$hostname" == "cx0" ]]; then
    echo "cx0" > masters

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
cx32" > slaves

else
    echo "Invalid hostname"
    exit -1
fi

echo "ALSO CHANGE: conf/core-site.xml, conf/mapred-site.xml"