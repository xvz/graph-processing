#!/bin/bash

# Based on number of machines, set the prefix names.
# This gives the hostnames of all machines.
#
# An invalid numbe rof machines results in an immediate
# termination of the including ("caller") shell/script.

case ${machines} in
    4)   name=cloud;;
    8)   name=cld;;
    16)  name=cw;;
    32)  name=cx;;
    64)  name=cy;;
    128) name=cz;;
    *) echo "Invalid number of machines"; exit -1;;
esac