#!/bin/sh

# If the Atelier B program is located on a different path, change this value.
ATB_FOLDER_PATH=/opt/atelierb-free-24.04.2

# Exit if there is not AtelierB file in the current folder
ABWS=$PWD
if [ ! -f "$ABWS/AtelierB" ]; then
    echo "Error: Configuration file 'AtelierB' not found in $ABWS"
    exit 1
fi

# DO NOT EDIT THIS PART

LD_LIBRARY_PATH='$ORIGIN':'$ORIGIN/lib':$LD_LIBRARY_PATH

export LD_LIBRARY_PATH
$ATB_FOLDER_PATH/bin/bbatch -r=$ABWS/AtelierB $*
