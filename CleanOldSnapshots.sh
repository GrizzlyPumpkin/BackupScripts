#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
NEEDS_LOCK=true
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

log_message "Cleaning up old snapshots older than 30 days"

if [[ -n "$PRUNE_PING" ]]; then
    curl -s --retry 3 "$PRUNE_PING/start" > /dev/null || log_message "Warning: healthcheck start ping failed"
    log_message "Pinged healthcheck start"
fi

# --group-by "" disables grouping so all snapshots are treated as one set
restic forget --keep-within-daily 30d --group-by "" --prune $RESTIC_DRY_RUN_OPTION 2>&1 | log_message

if [[ -n "$PRUNE_PING" ]]; then
    curl -s --retry 3 "$PRUNE_PING" > /dev/null || log_message "Warning: healthcheck complete ping failed"
    log_message "Pinged healthcheck complete"
fi

log_message "Cleaned up old snapshots older than 30 days"
