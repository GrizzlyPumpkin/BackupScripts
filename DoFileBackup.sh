#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

log_message "Backing up files"

restic backup --exclude-file="$RESTIC_EXCLUDE_FILE" --files-from="$RESTIC_INCLUDE_FILE" --read-concurrency 10 --option s3.connections=8 --compression max $RESTIC_DRY_RUN_OPTION 2>&1 | log_message

log_message "Files backed up"
