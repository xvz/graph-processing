#!/bin/bash -e

if [ $# -ne 1 ]; then
    echo "usage: $0 [data size]"
    exit -1
fi

size=$1
hostname=$(hostname)

case ${hostname} in
    "cloud0") size=1;;
    "cld0") size=1;;
    "c0") size=2;;
    "cx0") size=2;;
    "cy0") size=3;;
    "cz0") size=3;;
    *) echo "Invalid hostname"; exit -1;;
esac


cd ../raw/
hadoop dfs -mkdir ./input

case ${size} in
    1)  hadoop dfs -put amazon*.txt ./input/;
        hadoop dfs -put google*.txt ./input/;
        hadoop dfs -put patents*.txt ./input/;;
    2)  hadoop dfs -put patents*.txt ./input/;
        hadoop dfs -put livejournal*.txt ./input/;
        hadoop dfs -put orkut*.txt ./input/;;
    3)  hadoop dfs -put orkut*.txt ./input/;
        hadoop dfs -put arabic*.txt ./input/;
        hadoop dfs -put twitter*.txt ./input/;;
    *) echo "Invalid size"; exit -1;;
esac 