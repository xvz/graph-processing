#!/bin/bash -e

# Disables the fix for diameter estimation.
#
# This should be done before running non-diameter estimation algs.

scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$scriptdir"/../common/get-dirs.sh

cd "$GPS_DIR"/src/java/gps/messages/storage
cp -f ArrayBackedIncomingMessageStorage.javaORIGINAL ArrayBackedIncomingMessageStorage.java

"$scriptdir"/recompile-gps.sh