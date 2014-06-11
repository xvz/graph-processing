#!/bin/bash -e

# Loads split input data, based on the cluster size.
#
# The size can be specified as an argument. Otherwise,
# it will be obtained based on ../common/get-hosts.sh.

commondir=$(dirname "${BASH_SOURCE[0]}")/../common
scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
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
    1)  "${scriptdir}"/split-input.sh amazon-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh google-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh patents-adj.txt ${NUM_MACHINES};;
    2)  "${scriptdir}"/split-input.sh livejournal-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh orkut-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh arabic-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh twitter-adj.txt ${NUM_MACHINES};;
    3)  "${scriptdir}"/split-input.sh livejournal-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh orkut-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh arabic-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh twitter-adj.txt ${NUM_MACHINES};
        "${scriptdir}"/split-input.sh uk0705-adj.txt ${NUM_MACHINES};;
    *) echo "Invalid size"; exit -1;;
esac

case ${size} in
    1)  echo "Uploading amazon-adj-split/...";  hadoop dfs -put amazon-adj-split/ ./input/;
        echo "Uploading google-adj-split/...";  hadoop dfs -put google-adj-split/ ./input/;
        echo "Uploading patents-adj-split/..."; hadoop dfs -put patents-adj-split/ ./input/;;
    2)  echo "Uploading livejournal-adj-split/..."; hadoop dfs -put livejournal-adj-split/ ./input/;
        echo "Uploading orkut-adj-split/...";       hadoop dfs -put orkut-adj-split/ ./input/;
        echo "Uploading arabic-adj-split/...";      hadoop dfs -put arabic-adj-split/ ./input/;
        echo "Uploading twitter-adj-split/...";     hadoop dfs -put twitter-adj-split/ ./input/;;
    3)  echo "Uploading livejournal-adj-split/..."; hadoop dfs -put livejournal-adj-split/ ./input/;
        echo "Uploading orkut-adj-split/...";       hadoop dfs -put orkut-adj-split/ ./input/;
        echo "Uploading arabic-adj-split/...";      hadoop dfs -put arabic-adj-split/ ./input/;
        echo "Uploading twitter-adj-split/...";     hadoop dfs -put twitter-adj-split/ ./input/;
        echo "Uploading uk0705-adj-split/...";      hadoop dfs -put uk0705-adj-split/ ./input/;;
    *) echo "Invalid size"; exit -1;;
esac

echo "Done."