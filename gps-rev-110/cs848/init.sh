#!/bin/bash -e

read -p "Any key to continue..." none

hostname=$(hostname)

if [[ "$hostname" == "cloud0" ]]; then
    echo "cloud1
cloud2
cloud3
cloud4" > slaves

    echo "-1 cloud0 54000
0 cloud1 54001
1 cloud2 54002
2 cloud3 54003
3 cloud4 54004" > cs848.cfg

elif [[ "$hostname" == "cld0" ]]; then
    echo "cld1
cld2
cld3
cld4
cld5
cld6
cld7
cld8" > slaves

    echo "-1 cld0 54000
0 cld1 54001
1 cld2 54002
2 cld3 54003
3 cld4 54004
4 cld5 54005
5 cld6 54006
6 cld7 54007
7 cld8 54008" > cs848.cfg

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
c16" > slaves

    echo "-1 c0 54000
0 c1 54001
1 c2 54002
2 c3 54003
3 c4 54004
4 c5 54005
5 c6 54006
6 c7 54007
7 c8 54008
8 c9 54009
9 c10 54010
10 c11 54011
11 c12 54012
12 c13 54013
13 c14 54014
14 c15 54015
15 c16 54016" > cs848.cfg

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
cx32" > slaves

    echo "-1 cx0 54000
0 cx1 54001
1 cx2 54002
2 cx3 54003
3 cx4 54004
4 cx5 54005
5 cx6 54006
6 cx7 54007
7 cx8 54008
8 cx9 54009
9 cx10 54010
10 cx11 54011
11 cx12 54012
12 cx13 54013
13 cx14 54014
14 cx15 54015
15 cx16 54016
16 cx17 54017
17 cx18 54018
18 cx19 54019
19 cx20 54020
20 cx21 54021
21 cx22 54022
22 cx23 54023
23 cx24 54024
24 cx25 54025
25 cx26 54026
26 cx27 54027
27 cx28 54028
28 cx29 54029
29 cx30 54030
30 cx31 54031
31 cx32 54032" > cs848.cfg
  
else
     echo "Invalid hostname"
    exit -1
fi

hadoop dfs -mkdir /user/ubuntu/gps-machine-config/
hadoop dfs -put cs848.cfg /user/ubuntu/gps-machine-config/
mkdir ~/var/tmp