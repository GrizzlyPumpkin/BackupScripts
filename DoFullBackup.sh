#!/bin/bash

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

echo "Starting backup $NOW"

# If DB backups are not needed this script will do nothing
source "$SCRIPTS_ROOT/DoSqlBackup.sh"
source "$SCRIPTS_ROOT/DoFileBackup.sh"
source "$SCRIPTS_ROOT/CleanSqlDump.sh"
source "$SCRIPTS_ROOT/DoPartialIntegrityCheck.sh"

if [[ "$BACKUP_COMPLETE_PING" != "" ]]; then
    curl --retry 3 $BACKUP_COMPLETE_PING
    echo " "
else
    echo "Skipping healthcheck ping as not configured"
fi

echo "Backup done $(date +%F.%H%M%S)!"