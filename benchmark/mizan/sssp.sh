#!/bin/bash -e

if [ $# -ne 4 ]; then
    echo "usage: $0 input-graph machines migration-mode source-vertex"
    echo ""
    echo "migration-mode: 0 for static (no dynamic migration)"
    echo "                1 for delayed migration"
    echo "                2 for mixed migration"
    exit -1
fi

source ../common/get-dirs.sh
source ../common/get-configs.sh

# place input into /user/${USER}/input/ (this is where preMizan looks)
# output of preMizan is in /user/${USER}/m_output/mizan_${inputgraph}_mhash_${workers}/
#  (or _mrange_${workers} if using range partitioning)
# output of algorithm is in /user/${USER}/mizan-output/
inputgraph=$(basename $1)

# we can have multiple workers per machine
machines=$2
workers=$(($machines * $MIZAN_WPM))

mode=$3
case ${mode} in
    0) modeflag="1";;
    1) modeflag="2";;
    2) modeflag="3";;
    *) echo "Invalid migration-mode"; exit -1;;
esac

src=$4

## log names
logname=sssp_${inputgraph}_${machines}_${mode}_"$(date +%Y%m%d-%H%M%S)"
logfile=${logname}_time.txt       # Mizan stats (incl. running time)


## start logging memory + network usage
../common/bench-init.sh ${logname}

## start algorithm run
mpirun -f slaves -np ${workers} "$MIZAN_DIR"/Release/Mizan-0.1b \
    -a 5 \
    --src ${src} \
    -u ${USER} \
    -g ${inputgraph} \
    -w ${workers} \
    -m ${modeflag} 2>&1 | tee -a ./logs/${logfile}

## finish logging memory + network usage
../common/bench-finish.sh ${logname}