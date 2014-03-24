#!/bin/bash -e

# Enables a fix for diameter estimation.
#
# This fix should be enabled only for diameter estimation,
# and should be disabled when running other algorithms.

scriptdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$scriptdir"/../common/get-dirs.sh

cd "$GPS_DIR"/src/java/gps/messages/storage
cp -f ArrayBackedIncomingMessageStorage.javaDIMEST ArrayBackedIncomingMessageStorage.java

"$scriptdir"/recompile-gps.sh