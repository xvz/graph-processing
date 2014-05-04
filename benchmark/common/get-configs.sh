#!/bin/bash

# Specifies system-specific configuration parameters
# used by the various scripts.
#
# NOTE: include/source using "$(dirname "${BASH_SOURCE[0]}")"
# as a part of the directory.

# maximum JVM heap size for Giraph (per machine)
# NOTE: to put changes into effect without re-initializing everything (i.e., ../init-all.sh),
#       run ../hadoop/init.sh; ../hadoop/restart-hadoop.sh 1
GIRAPH_XMX=14500M

# maximum JVM heap size for GPS (per WORKER, not machine)
GPS_WORKER_XMX=7250M
# max JVM heap size for GPS master
GPS_MASTER_XMX=4096M


# number of compute/input/output threads per machine
GIRAPH_THREADS=2

# number of workers per machine (WPM)
GPS_WPM=2
MIZAN_WPM=2   # NOTE: re-run premizan if this is changed