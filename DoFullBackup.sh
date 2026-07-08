#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
NEEDS_LOCK=true
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

run_backup_hook() {
    local HOOK_NAME="$1"
    local HOOK_SCRIPT="$2"

    if [[ -z "$HOOK_SCRIPT" ]]; then
        return 0
    fi

    if [[ ! -f "$HOOK_SCRIPT" ]]; then
        log_message "FATAL: $HOOK_NAME hook script not found: $HOOK_SCRIPT"
        return 1
    fi

    if [[ ! -x "$HOOK_SCRIPT" ]]; then
        log_message "FATAL: $HOOK_NAME hook script is not executable: $HOOK_SCRIPT"
        return 1
    fi

    log_message "Running $HOOK_NAME hook: $HOOK_SCRIPT"

    set +e
    "$HOOK_SCRIPT" 2>&1 | log_message
    local HOOK_EXIT_CODE=${PIPESTATUS[0]}
    set -e

    if [[ $HOOK_EXIT_CODE -ne 0 ]]; then
        log_message "FATAL: $HOOK_NAME hook failed with exit code $HOOK_EXIT_CODE"
        return $HOOK_EXIT_CODE
    fi

    log_message "$HOOK_NAME hook complete"
}

run_post_backup_hook_on_exit() {
    local BACKUP_EXIT_CODE=$?

    if [[ -n "$POST_BACKUP_SCRIPT" ]]; then
        run_backup_hook "Post-backup" "$POST_BACKUP_SCRIPT"
        local POST_HOOK_EXIT_CODE=$?

        if [[ $BACKUP_EXIT_CODE -eq 0 && $POST_HOOK_EXIT_CODE -ne 0 ]]; then
            BACKUP_EXIT_CODE=$POST_HOOK_EXIT_CODE
        fi
    fi

    exit "$BACKUP_EXIT_CODE"
}

trap run_post_backup_hook_on_exit EXIT

log_message "Starting backup"

if [[ -n "$BACKUP_COMPLETE_PING" ]]; then
    curl -s --retry 3 "$BACKUP_COMPLETE_PING/start" > /dev/null || log_message "Warning: healthcheck start ping failed"
    log_message "Pinged healthcheck start"
fi

run_backup_hook "Pre-backup" "$PRE_BACKUP_SCRIPT" || { log_message "FATAL: Pre-backup hook failed"; exit 1; }

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
