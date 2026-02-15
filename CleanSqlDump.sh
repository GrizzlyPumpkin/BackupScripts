#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

if [[ "$DB_BACKUP" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        log_message "Skipping cleanup as we're in a dry run."
    else
        rm -f "$DB_FILE"
        log_message "Cleaned up SQL dump"
    fi
fi
