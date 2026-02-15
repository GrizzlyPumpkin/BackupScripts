#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

if [[ "$DB_BACKUP" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        log_message "Skipping DB dump as we're in a dry run."
    else
        log_message "Starting DB backup"
        mysqldump --defaults-file="$DB_PASSWORD_FILE" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" "$DB_NAME" --force --single-transaction --quick --compact --extended-insert --order-by-primary $DB_EXTRA_OPTIONS | gzip > "${DB_FILE}.tmp"
        mv "${DB_FILE}.tmp" "$DB_FILE"
        log_message "DB backed up to $DB_FILE"
    fi
fi
