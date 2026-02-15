#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
NEEDS_LOCK=true
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

log_message "Performing full integrity check"

if [[ -n "$INTEGRITY_CHECK_PING" ]]; then
    curl -s --retry 3 "$INTEGRITY_CHECK_PING/start" > /dev/null || log_message "Warning: healthcheck start ping failed"
    log_message "Pinged healthcheck start"
fi

restic check --read-data $RESTIC_DRY_RUN_OPTION 2>&1 | log_message

if [[ -n "$INTEGRITY_CHECK_PING" ]]; then
    curl -s --retry 3 "$INTEGRITY_CHECK_PING" > /dev/null || log_message "Warning: healthcheck complete ping failed"
    log_message "Pinged healthcheck complete"
fi

log_message "Full integrity check complete"
