#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

log_message "Starting backup"

# If DB backups are not needed this script will do nothing
(set -o pipefail && source "$SCRIPTS_ROOT/DoSqlBackup.sh")
(set -o pipefail && source "$SCRIPTS_ROOT/DoFileBackup.sh")
(set -o pipefail && source "$SCRIPTS_ROOT/CleanSqlDump.sh")
(set -o pipefail && source "$SCRIPTS_ROOT/DoPartialIntegrityCheck.sh")

if [[ "$BACKUP_COMPLETE_PING" != "" ]]; then
    curl -s --retry 3 $BACKUP_COMPLETE_PING > /dev/null
    log_message "Pinged healthcheck"
else
    log_message "Starting backup"
fi

log_message "Backup done"