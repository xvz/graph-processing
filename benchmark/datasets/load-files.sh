#!/bin/bash -e

# Loads the input data, based on the cluster size.
#
# The size can be specified as an argument. Otherwise,
# it will be obtained from the hostname of the master.
#
# usage: $0 [size]

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-dirs.sh

if [ $# -eq 0 ]; then
    source "$commondir"/get-hosts.sh

    case ${machines} in
        4) size=1;;
        8) size=1;;
        16) size=2;;
        32) size=2;;
        64) size=3;;
        128) size=3;;
        *) echo "usage: $0 size";
           echo "";
           echo "size: 1 for amazon, google, patents";
           echo "      2 for livejournal, orkut, arabic, twitter";
           echo "      3 for livejournal, orkut, arabic, twitter, uk0705";
           exit -1;;
    esac
else
    size=$1
fi

cd "$DATASET_DIR"

hadoop dfsadmin -safemode wait > /dev/null
hadoop dfs -mkdir ./input || true    # no problem if it already exists

case ${size} in
    1)  hadoop dfs -put amazon*.txt ./input/;
        hadoop dfs -put google*.txt ./input/;
        hadoop dfs -put patents*.txt ./input/;;
    2)  hadoop dfs -put livejournal*.txt ./input/;
        hadoop dfs -put orkut*.txt ./input/;
        hadoop dfs -put arabic*.txt ./input/;
        hadoop dfs -put twitter-adj.txt ./input/;;
    3)  hadoop dfs -put livejournal*.txt ./input/;
        hadoop dfs -put orkut*.txt ./input/;
        hadoop dfs -put arabic*.txt ./input/;
        hadoop dfs -put twitter*.txt ./input/;
        hadoop dfs -put uk0705-adj.txt ./input/;;
        hadoop dfs -put uk0705-mst-adj.txt ./input/;;
    *) echo "Invalid size"; exit -1;;
esac