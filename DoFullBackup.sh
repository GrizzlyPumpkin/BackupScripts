#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
NEEDS_LOCK=true
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

# The after hook is armed before the before hook runs so it can clean up a
# partially-created artifact if either the before hook or backup fails.
RUN_AFTER_BACKUP_HOOK=false

finish_backup() {
    local exit_status=$?
    local hook_status=0
    trap - EXIT

    if [[ "$RUN_AFTER_BACKUP_HOOK" == true ]]; then
        run_backup_hook "after" "$AFTER_BACKUP_HOOK" || hook_status=$?
        if (( exit_status == 0 && hook_status != 0 )); then
            exit_status=$hook_status
        fi
    fi

    if (( exit_status != 0 )); then
        send_fail_ping "$BACKUP_COMPLETE_PING"
    fi

    exit "$exit_status"
}

trap finish_backup EXIT

log_message "Starting backup"

# Pre-flight checks
preflight_check_repo || exit 1
preflight_check_disk_space || exit 1

if [[ -n "$BACKUP_COMPLETE_PING" ]]; then
    curl -s --retry 3 "$BACKUP_COMPLETE_PING/start" > /dev/null || log_message "Warning: healthcheck start ping failed"
    log_message "Pinged healthcheck start"
fi

if [[ "$DRY_RUN" == true ]]; then
    if [[ -n "$BEFORE_BACKUP_HOOK" || -n "$AFTER_BACKUP_HOOK" ]]; then
        log_message "Skipping backup hooks in dry run"
    fi
else
    if [[ -n "$AFTER_BACKUP_HOOK" ]]; then
        RUN_AFTER_BACKUP_HOOK=true
    fi
    run_backup_hook "before" "$BEFORE_BACKUP_HOOK"
fi

# If DB backups are not needed this script will do nothing
(source "$SCRIPTS_ROOT/DoSqlBackup.sh") || { log_message "FATAL: SQL backup failed"; exit 1; }
(source "$SCRIPTS_ROOT/DoFileBackup.sh") || { log_message "FATAL: File backup failed"; exit 1; }

if [[ "$RUN_AFTER_BACKUP_HOOK" == true ]]; then
    RUN_AFTER_BACKUP_HOOK=false
    run_backup_hook "after" "$AFTER_BACKUP_HOOK"
fi

(source "$SCRIPTS_ROOT/CleanSqlDump.sh") || { log_message "FATAL: SQL dump cleanup failed"; exit 1; }
(source "$SCRIPTS_ROOT/DoPartialIntegrityCheck.sh") || { log_message "FATAL: Partial integrity check failed"; exit 1; }

if [[ -n "$BACKUP_COMPLETE_PING" ]]; then
    curl -s --retry 3 "$BACKUP_COMPLETE_PING" > /dev/null || log_message "Warning: healthcheck complete ping failed"
    log_message "Pinged healthcheck complete"
fi

log_message "Backup done"

# Clear the EXIT trap after all steps complete successfully.
trap - EXIT
