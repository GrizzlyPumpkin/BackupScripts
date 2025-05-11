#!/bin/bash

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

log_message "Cleaning up old snapshots older than 30 days"

restic forget --keep-within-daily 30d --group-by "" --prune $RESTIC_DRY_RUN_OPTION 2>&1 | log_message

log_message "Cleaning up old snapshots older than 30 days"