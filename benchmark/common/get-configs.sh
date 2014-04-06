#!/bin/bash

# Specifies system-specific configuration parameters
# used by the various scripts.
#
# NOTE: include/source using "$(dirname "${BASH_SOURCE[0]}")"
# as a part of the directory.

# maximum JVM heap size for Giraph (per machine)
GIRAPH_XMX=14500M

# maximum JVM heap size for GPS (per WORKER, not machine)
GPS_WORKER_XMX=7250
# max JVM heap size for GPS master
GPS_MASTER_XMX=4096


# number of compute threads per machine
GIRAPH_COMPUTE_THREADS=4

# number of workers per machine (WPM)
GPS_WPM=2
MIZAN_WPM=2