#!/bin/bash -e

# Loads the input data, based on the cluster size.
#
# The size can be specified as an argument. Otherwise,
# it will be obtained based on ../common/get-hosts.sh.

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
source "$commondir"/get-dirs.sh
source "$commondir"/get-hosts.sh

if [ $# -eq 0 ]; then
    case ${NUM_MACHINES} in
        4) size=1;;
        8) size=1;;
        16) size=2;;
        32) size=2;;
        64) size=3;;
        128) size=3;;
        *) echo "Invalid number of machines.";
           echo "usage: $0 size";
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
    1)  echo "Uploading amazon*.txt...";  hadoop dfs -put amazon*.txt ./input/;
        echo "Uploading google*.txt...";  hadoop dfs -put google*.txt ./input/;
        echo "Uploading patents*.txt..."; hadoop dfs -put patents*.txt ./input/;;
    2)  echo "Uploading livejournal*.txt..."; hadoop dfs -put livejournal*.txt ./input/;
        echo "Uploading orkut*.txt...";       hadoop dfs -put orkut*.txt ./input/;
        echo "Uploading arabic*.txt...";      hadoop dfs -put arabic*.txt ./input/;
        echo "Uploading twitter-adj.txt...";  hadoop dfs -put twitter-adj.txt ./input/;;
    3)  echo "Uploading livejournal*.txt..."; hadoop dfs -put livejournal*.txt ./input/;
        echo "Uploading orkut*.txt...";       hadoop dfs -put orkut*.txt ./input/;
        echo "Uploading arabic*.txt...";      hadoop dfs -put arabic*.txt ./input/;
        echo "Uploading twitter*.txt...";     hadoop dfs -put twitter*.txt ./input/;
        echo "Uploading uk0705-adj.txt...";   hadoop dfs -put uk0705-adj.txt ./input/;
        echo "Uploading uk0705-mst-adj.txt..."; hadoop dfs -put uk0705-mst-adj.txt ./input/;;
    *) echo "Invalid size"; exit -1;;
esac

echo "Done."