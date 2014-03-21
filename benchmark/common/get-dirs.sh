#!/bin/bash

# Specifies the absolute paths of the systems and other things.
#
# Use quotes if path has spaces (e.g., "../bad folder name/"),
# but be warned that things will break...
#
# NOTE: if the including script will be included in other
# scripts, use "$(dirname "${BASH_SOURCE[0]}")" as a part
# of the directory to be safe.

HADOOP_DIR=/user/ubuntu/hadoop-1.0.4/
JAVA_DIR=/user/ubuntu/jdk1.6.0_30/

GIRAPH_DIR=/user/ubuntu/giraph-1.0.0/
GPS_DIR=/user/ubuntu/gps-rev-110/
GPS_LOGS=/user/ubuntu/var/tmp/
GRAPHLAB_DIR=/user/ubuntu/graphlab-2.2/
MIZAN_DIR=/user/ubuntu/Mizan-0.1bu1/