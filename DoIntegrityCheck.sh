#!/bin/bash

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

log_message "Performing full integrity check"

restic check --read-data $RESTIC_DRY_RUN_OPTION 2>&1 | log_message

if [[ "$INTEGRITY_CHECK_PING" != "" ]]; then
    curl --retry 3 $INTEGRITY_CHECK_PING
    log_message "Ping sent"
else
    log_message "Skipping healthcheck ping as not configured"
fi

log_message "Done!"