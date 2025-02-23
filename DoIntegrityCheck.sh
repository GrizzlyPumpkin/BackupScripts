#!/bin/bash

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

echo "Performing full integrity check $NOW"

restic check --read-data $RESTIC_DRY_RUN_OPTION

if [[ "$INTEGRITY_CHECK_PING" != "" ]]; then
    curl --retry 3 $INTEGRITY_CHECK_PING
    echo " "
else
    echo "Skipping healthcheck ping as not configured"
fi

echo "Done!"