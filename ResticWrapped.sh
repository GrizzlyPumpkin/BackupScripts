#!/bin/bash

# Exit on error
set -e

# Simple wrapper to ensure our config is loaded first
# Does not acquire a lock so it can be used while backups are running

# Load config if not already loaded
if [ -z "${SERVER_BACKUP_SCRIPT+x}" ]; then source "$(dirname "$0")/Init.sh"; fi

restic "$@"
