#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

log_message "Cleaning up old snapshots older than 30 days"

if [[ "$PRUNE_PING" != "" ]]; then
    curl -s --retry 3 "$PRUNE_PING/start" > /dev/null
    log_message "Pinged healthcheck start"
fi

restic forget --keep-within-daily 30d --group-by "" --prune $RESTIC_DRY_RUN_OPTION 2>&1 | log_message $1

if [[ "$PRUNE_PING" != "" ]]; then
    curl -s --retry 3 "$PRUNE_PING" > /dev/null
    log_message "Pinged healthcheck complete"
fi

log_message "Cleaned up old snapshots older than 30 days"