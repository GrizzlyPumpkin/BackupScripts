#!/bin/bash

# Exit on error
set -e

# Simple wrapper to ensure our config is loaded first

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

restic "$@"