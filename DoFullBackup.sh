#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
NEEDS_LOCK=true
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

log_message "Starting backup"

if [[ -n "$BACKUP_COMPLETE_PING" ]]; then
    curl -s --retry 3 "$BACKUP_COMPLETE_PING/start" > /dev/null || log_message "Warning: healthcheck start ping failed"
    log_message "Pinged healthcheck start"
fi

# If DB backups are not needed this script will do nothing
(source "$SCRIPTS_ROOT/DoSqlBackup.sh") || { log_message "FATAL: SQL backup failed"; exit 1; }
(source "$SCRIPTS_ROOT/DoFileBackup.sh") || { log_message "FATAL: File backup failed"; exit 1; }
(source "$SCRIPTS_ROOT/CleanSqlDump.sh") || { log_message "FATAL: SQL dump cleanup failed"; exit 1; }
(source "$SCRIPTS_ROOT/DoPartialIntegrityCheck.sh") || { log_message "FATAL: Partial integrity check failed"; exit 1; }

if [[ -n "$BACKUP_COMPLETE_PING" ]]; then
    curl -s --retry 3 "$BACKUP_COMPLETE_PING" > /dev/null || log_message "Warning: healthcheck complete ping failed"
    log_message "Pinged healthcheck complete"
fi

log_message "Backup done"
