#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

log_message "Daily check to ensure integrity has run recently."

LAST_RUN=$(cat $INTEGRITY_LAST_RUN_FILE 2>/dev/null || echo 0)

if [[ "$INTEGRITY_CHECK_PING" != "" ]]; then
    if (( NOW_INT - LAST_RUN < INTEGRITY_MAX_AGE)); then
        curl --retry 3 $INTEGRITY_CHECK_PING
        log_message "Success ping sent"
    else
        if [[ "$INTEGRITY_CHECK_PING_DOWN" != "" ]]; then
            curl --retry 3 $INTEGRITY_CHECK_PING_DOWN
            log_message "Failed ping sent"
        else
            log_message "Failed but not sending ping as not configured"
        fi
    fi
else
    log_message "Skipping healthcheck ping as not configured"
fi

log_message "Done!"