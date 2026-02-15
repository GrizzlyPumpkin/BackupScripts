#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

log_message "Performing full integrity check"

if [[ "$INTEGRITY_CHECK_PING" != "" ]]; then
    curl -s --retry 3 "$INTEGRITY_CHECK_PING/start" > /dev/null
    log_message "Pinged healthcheck start"
fi

restic check --read-data $RESTIC_DRY_RUN_OPTION 2>&1 | log_message $1

if [[ "$INTEGRITY_CHECK_PING" != "" ]]; then
    curl -s --retry 3 "$INTEGRITY_CHECK_PING" > /dev/null
    log_message "Pinged healthcheck complete"
fi


log_message "Done!"