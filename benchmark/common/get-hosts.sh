#!/bin/bash

# Based on the hostname of the master, set the prefix name
# and the number of slave/worker machines. Together, this
# gives the hostnames of all worker machines.
#
# For example, a hostname of cloud0 means that the worker
# machines are named cloud1, cloud2, cloud3, cloud4.
#
# An invalid hostname results in an immediate termination
# of the including ("caller") shell/script.
#
# NOTE: if the including script will be included in other
# scripts, use "$(dirname "${BASH_SOURCE[0]}")" as a part
# of the directory to be safe.

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; nodes=4;;
    "cld0") name=cld; nodes=8;;
    "c0") name=c; nodes=16;;
    "cx0") name=cx; nodes=32;;
    "cy0") name=cy; nodes=64;;
    "cz0") name=cz; nodes=128;;
    *) echo "Invalid hostname"; exit -1;;
esac
