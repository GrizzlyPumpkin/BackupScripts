#!/bin/bash

# Exit on error
set -e

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

if [[ "$DO_PARTIAL_REPO_CHECK" == true ]]; then
	log_message "Doing partial integrity check"

	restic check --read-data-subset=$PARTIAL_REPO_CHECK_SUBSET $RESTIC_DRY_RUN_OPTION 2>&1 | log_message $1
fi