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
# of the directory.

hostname=$(hostname)

case ${hostname} in
    "cloud0") name=cloud; machines=4;;
    "cld0") name=cld; machines=8;;
    "cw0") name=cw; machines=16;;
    "cx0") name=cx; machines=32;;
    "cy0") name=cy; machines=64;;
    "cz0") name=cz; machines=128;;
    "YBOX") name=YBOX; machines=-1;;    # for testing on a single machine
    *) echo "Invalid hostname"; exit -1;;
esac

# Note: when testing on a single machine, setting machines to -1
# will prevent bench-init and bench-finish from doing anything.