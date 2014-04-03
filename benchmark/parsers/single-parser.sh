#!/bin/bash -e

# This parses a single experiment's logs, extracting
# running time, total time, min/max/avg per-worker memory usage,
# and total network I/O across workers.
#
# Log files need not be in the working directory ($PWD).

if [ $# -ne 2 ]; then
    echo "usage: $0 system time-log"
    echo ""
    echo "system: 1 for Giraph, 2 for GPS, 3 for GraphLab, 4 for Mizan"
    echo "time-log: experiment's time log file"
    echo "          (e.g. pagerank_orkut-adj.txt_16_20140101-123050_time.txt)"
    exit -1
fi

# constants
SYS_GIRAPH=1
SYS_GPS=2
SYS_GRAPHLAB=3
SYS_MIZAN=4

#################
# Parse args
#################
# check system arg
system=$1
case $system in
    $SYS_GIRAPH) ;;
    $SYS_GPS) ;;
    $SYS_GRAPHLAB) ;;
    $SYS_MIZAN) ;;
    *) echo "Invalid system"; exit -1;;
esac

logname=$(echo $(basename "$2") | sed 's/_time.txt$//g')

# move to where the logs are
cd "$(dirname "$2")"

# initial "header" output, containing extra info where relevant
echo ""
if [[ $system -eq $SYS_GIRAPH && -f "${logname}_time.txt" ]]; then
    jobid=$(grep "Job complete: " "${logname}_time.txt" | cut -c 56-100)
    echo "${logname} (${jobid})"
elif [[ $system -eq $SYS_MIZAN && $(echo "$logname" | sed 's/_.*//g') != "premizan" ]]; then
    echo "${logname} (excludes premizan time)"
else
    echo "${logname}"
fi

##################################
# Ensure all files are present
##################################
if [[ ! -f "${logname}_time.txt" ]]; then
    echo "  ERROR: ${logname}_time.txt missing!"
    exit -1
fi

nodes=$(echo "$logname" | sed 's/_/ /g' | awk '{print $3}')

for (( i = 0; i <= $nodes; i++ )); do
    # some files are critical, others are not
    if [[ ! -f "${logname}_${i}_mem.txt" ]]; then
        echo "  ERROR: ${logname}_${i}_mem.txt missing!"
        exit -1
    elif [[ ! -f "${logname}_${i}_nbt.txt" ]]; then
        echo "  ERROR: ${logname}_${i}_nbt.txt missing!"
        exit -1
    elif [[ ! -f "${logname}_${i}_cpu.txt" ]]; then
        echo "  WARNING: ${logname}_${i}_cpu.txt missing!"
    elif [[ ! -f "${logname}_${i}_net.txt" ]]; then
        echo "  WARNING: ${logname}_${i}_net.txt missing!"
    fi
done


#######################################
# Time parsing, unique for each system
#######################################
if [[ $system -eq $SYS_GIRAPH ]]; then
    setup=$(grep "Setup " "${logname}_time.txt" | sed 's/.*(milliseconds)=//g')
    input=$(grep "Input superstep " "${logname}_time.txt" | sed 's/.*(milliseconds)=//g')
    shutdown=$(grep "Shutdown " "${logname}_time.txt" | sed 's/.*(milliseconds)=//g')
    total=$(grep "Total (mil" "${logname}_time.txt" | sed 's/.*(milliseconds)=//g')

    # all times are in ms, so have to convert it to seconds
    # must use perl (or something else) as $((..)) can't handle floats
    time_tot=$(perl -e "print( $total / 1000 )")
    time_io=$(perl -e "print( ($setup + $input + $shutdown) / 1000 )")
    time_run=$(perl -e "print( $time_tot - $time_io )")

elif [[ $system -eq $SYS_GPS ]]; then
    start=$(grep "^SYSTEM_START_TIME " "${logname}_time.txt" | awk '{print $2}')
    computestart=$(grep "^START_TIME " "${logname}_time.txt" | awk '{print $2}')
    end=$(grep -- "^-1-LATEST_STATUS_TIMESTAMP " "${logname}_time.txt" | awk '{print $2}')

    # all times are in ms, so have to convert it to seconds
    # must use perl (or something else) as $((..)) can't handle floats
    time_tot=$(perl -e "print( ($end - $start) / 1000 )")
    time_io=$(perl -e "print( ($computestart - $start) / 1000 )")
    time_run=$(perl -e "print( $time_tot - $time_io )")

elif [[ $system -eq $SYS_GRAPHLAB ]]; then
    time_tot=$(grep "TOTAL TIME (sec)" "${logname}_time.txt" | awk '{print $4}')
    time_run=$(grep "Finished Running engine" "${logname}_time.txt" | awk '{print $5}')
    time_io=$(perl -e "print( $time_tot - $time_run )")

elif [[ $system -eq $SYS_MIZAN ]]; then
    # Mizan's premizan logs are distinct from normal algorithm runs
    alg=$(echo "$logname" | sed 's/_.*//g')
    if [[ "$alg" == "premizan" ]]; then
        time_tot=$(grep "TOTAL TIME (sec)" "${logname}_time.txt" | awk '{print $4}')
        time_io=$time_tot
        time_run=0
    else
        time_run=$(grep "TIME: Total Running Time without IO = " "${logname}_time.txt" | awk '{print $8}')
        time_tot=$(grep "TIME: Total Running Time =" "${logname}_time.txt" | awk '{print $6}')
        time_io=$(($time_tot - $time_run))
    fi
fi


#############################
# Generic memory parsing
#############################
# no match = 0 files
shopt -s nullglob

# iterate over logs from each WORKER node (i.e., exclude master)
FILES=(${logname}_{[0-9][0-9],[1-9]}_mem.txt)

mem=""
for file in "${FILES[@]}"; do
    maxmem=$(awk '{print $3}' "$file" | sort -rn | head -n 1)
    minmem=$(awk '{print $3}' "$file" | sort -n | head -n 1)
    initmem=$(awk '{print $3}' "$file" | head -n 1)

    # convert largest difference into GBytes, and add it on to the existing results
    mem="${mem} $(perl -e "print( (${maxmem} - ${minmem})/(1024*1024) )")"
done

# more hacky perl
mem_min=$(echo "$mem" | perl -ne 'use List::Util qw(min); @arr = split(" ", $_); print( min @arr )')
mem_max=$(echo "$mem" | perl -ne 'use List::Util qw(max); @arr = split(" ", $_); print( max @arr )')
mem_avg=$(echo "$mem" | perl -ne 'use List::Util qw(sum); @arr = split(" ", $_); print( sum(@arr)/@arr )')


###########################
# Generic network parsing
###########################
# iterate over logs from each WORKER node (i.e., exclude master)
FILES=(${logname}_{[0-9][0-9],[1-9]}_nbt.txt)

# running totals
ethrecvsum=0   # ethernet received
ethsentsum=0   # ethernet sent
lorecvsum=0    # loopback received
losentsum=0    # loopback sent
for file in "${FILES[@]}"; do
    read -a eth <<< $(grep "eth0" "$file" | paste -s -d ' ')
    read -a lo <<< $(grep "lo" "$file" | paste -s -d ' ')

    # arrays are a little hacky: [18] is final count, [1] is initial count
    # all are integers, so ok to do $((...)) math
    ethrecvsum=$((${ethrecvsum} + ${eth[18]} - ${eth[1]}))
    ethsentsum=$((${ethsentsum} + ${eth[26]} - ${eth[9]}))
    lorecvsum=$((${lorecvsum} + ${lo[18]} - ${lo[1]}))
    losentsum=$((${losentsum} + ${lo[26]} - ${lo[9]}))
done

# ethernet is the relevant network I/O measure (in GBytes)
eth_recv=$(perl -e "print( ${ethrecvsum}/(1024*1024*1024) )")
eth_sent=$(perl -e "print( ${ethsentsum}/(1024*1024*1024) )")


##################
# Output results
##################
echo "-------------------------------------------------------------------------------------------------"
echo " Total time |   IO time |  Running time |  Mem per worker (min/max/avg)  |  Net I/O (recv/sent)  "
echo "------------+-----------+---------------+--------------------------------+-----------------------"
printf "  %8.2fs | %8.2fs |     %8.2fs | %7.3f / %7.3f / %7.3f GB | %7.3f / %7.3f GB \n" \
    $time_tot $time_io $time_run \
    $mem_min $mem_max $mem_avg \
    $eth_recv $eth_sent
echo "-------------------------------------------------------------------------------------------------"