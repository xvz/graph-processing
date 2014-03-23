#!/bin/bash

# Specifies the absolute paths of the systems and other things.
#
# If path has spaces, escape the spaces AND quote it. For example,
# SOME_DIR="/home/me/not\ a\ great\ folder\ name/".
#
# NOTE: if the including script will be included in other
# scripts, use "$(dirname "${BASH_SOURCE[0]}")" as a part
# of the directory.

DIR_PREFIX=/home/ubuntu
#DIR_PREFIX=/home/young/cs848   # for testing on a single machine

# location of datasets/input graphs
DATASET_DIR="$DIR_PREFIX"/datasets/raw/

# $JAVA_DIR/bin/java should be the Java binary that is
# used by all systems (incl. Hadoop) that need Java
JAVA_DIR="$DIR_PREFIX"/jdk1.6.0_30/

# HADOOP_DATA is where HDFS files and Hadoop logs are stored
HADOOP_DIR="$DIR_PREFIX"/hadoop-1.0.4/
HADOOP_DATA_DIR="$DIR_PREFIX"/hadoop_data/

GIRAPH_DIR="$DIR_PREFIX"/giraph-1.0.0/

# These must match "GPS_DIR" and "GPS_LOG_DIRECTORY" of $GPS_DIR/conf/gps-env.sh
GPS_DIR="$DIR_PREFIX"/gps-rev-110/
#GPS_DIR="$DIR_PREFIX"/gps-rev-90/
GPS_LOGS_DIR="$DIR_PREFIX"/var/tmp/

GRAPHLAB_DIR="$DIR_PREFIX"/graphlab-2.2/
MIZAN_DIR="$DIR_PREFIX"/Mizan-0.1bu1/