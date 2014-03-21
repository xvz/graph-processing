#!/bin/bash -e

# This runs GPS's web interface to view old runs/logs.
#
# NOTE: Compile debug_monitoring_runner.jar using $GPS_DIR/make_debug_monitoring_runner_jar.sh

source "$(dirname "${BASH_SOURCE[0]}")"/../common/get-dirs.sh

java -jar "$GPS_DIR"/debug_monitoring_runner.jar -hcf "$GIRAPH_DIR"/conf/core-site.xml -msfp /user/${USER}/gps/stats-* -port 4444