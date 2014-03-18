#!/bin/bash -e

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; nodes=4;;
    "cld0") name=cld; nodes=8;;
    "c0") name=c; nodes=16;;
    "cx0") name=cx; nodes=32;;
    "cy0") name=cy; nodes=64;;
    "cz0") name=cz; nodes=128;;
    *) echo "Invalid hostname, killing locally...";
       # do a quick kill anyway---useful for testing on a single machine
       kill $(ps aux | grep "[j]obcache/job_[0-9]\{12\}_[0-9]\{4\}/" | awk '{print $2}');
       exit -1;;
esac

# Kill all Java instances corresponding to Giraph jobs.
# This is needed as they don't terminate automatically (they hang around consuming memory).
#
# NOTE: this will kill ALL jobs, including ongoing ones!
for ((i = 0; i <= ${nodes}; i++)); do
    # [j] is a nifty trick to avoid "grep" showing up as a result
    ssh ${name}$i "kill \$(ps aux | grep \"[j]obcache/job_[0-9]\{12\}_[0-9]\{4\}/\" | awk '{print \$2}')" &
done
wait