#!/bin/bash

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

echo "Cleaning up old snapshots older than 30 days: $NOW"

restic forget --keep-within-daily 30d --group-by "" --prune $RESTIC_DRY_RUN_OPTION

echo "Done"