#!/bin/bash
# Shared initialisation logic for all backup scripts.
# This file is tracked in git and should not be edited on individual servers.
# Server-specific settings belong in Config.sh (see Config.sh.example).

# Guard to prevent loading more than once
SERVER_BACKUP_SCRIPT=true

SCRIPTS_ROOT="$(cd "$(dirname "$0")" && pwd)"
NOW=$(date +%F.%H%M%S)

# Load server-specific config
if [[ ! -f "$SCRIPTS_ROOT/Config.sh" ]]; then
    echo "FATAL: Config.sh not found in $SCRIPTS_ROOT. Copy Config.sh.example and fill in your values." >&2
    exit 1
fi
source "$SCRIPTS_ROOT/Config.sh"

# Derived paths (not user-configurable)
RESTIC_EXCLUDE_FILE="$SCRIPTS_ROOT/ExcludeFiles.txt"
RESTIC_INCLUDE_FILE="$SCRIPTS_ROOT/IncludeFiles.txt"
DB_PASSWORD_FILE="$SCRIPTS_ROOT/DB.cnf"
DB_FILE="$SCRIPTS_ROOT/Temp/$NOW.sql.gz"
LOG_FOLDER="/var/log/pumpkin"
LOG_FILE="$LOG_FOLDER/backups.log"

# Defaults for optional config values (can be overridden in Config.sh)
DO_PARTIAL_REPO_CHECK="${DO_PARTIAL_REPO_CHECK:-true}"
PARTIAL_REPO_CHECK_SUBSET="${PARTIAL_REPO_CHECK_SUBSET:-5%}"
DB_MIN_DISK_MB="${DB_MIN_DISK_MB:-2048}" # Minimum free disk space (MB) required for SQL dumps

# Dry run support (can be set in Config.sh or via environment variable)
DRY_RUN="${DRY_RUN:-false}"

# Backend-specific options used by restic backup. Keep S3 tuning for existing
# repositories without passing S3-only options to other restic backends.
RESTIC_BACKUP_BACKEND_OPTIONS=()
if [[ "$RESTIC_REPOSITORY" == s3:* ]]; then
    RESTIC_BACKUP_BACKEND_OPTIONS=(--option s3.connections=8)
fi

if [[ "$DRY_RUN" = true ]]; then
    RESTIC_DRY_RUN_OPTION="--dry-run"
else
    RESTIC_DRY_RUN_OPTION=""
fi

# Create required directories
mkdir -p "$SCRIPTS_ROOT/Temp"
mkdir -p "$LOG_FOLDER"

# Function to log messages
log_message() {
    if [[ -n "$1" ]]; then
        local DATE
        DATE=$(date +%F.%H%M%S)
        echo "[$DATE] $1" >> "$LOG_FILE"
    else
        while IFS= read -r data || [[ -n "$data" ]]; do
            log_message "$data"
        done
    fi
}

# Send a /fail ping to a healthchecks.io endpoint
send_fail_ping() {
    local ping_url="$1"
    if [[ -n "$ping_url" ]]; then
        curl -s --retry 3 "$ping_url/fail" > /dev/null || log_message "Warning: healthcheck fail ping failed"
    fi
}

# Verify the restic repository is reachable and credentials work
preflight_check_repo() {
    log_message "Pre-flight: checking repository connectivity"
    if ! restic cat config > /dev/null 2>&1; then
        log_message "FATAL: Cannot reach restic repository. Check credentials and network."
        return 1
    fi
}

# Verify sufficient disk space for SQL dump (only relevant when DB_BACKUP=true)
preflight_check_disk_space() {
    if [[ "$DB_BACKUP" != true ]]; then return 0; fi
    log_message "Pre-flight: checking disk space for SQL dump"
    local available_mb
    available_mb=$(df -BM --output=avail "$SCRIPTS_ROOT/Temp" | tail -1 | tr -d ' M')
    if (( available_mb < DB_MIN_DISK_MB )); then
        log_message "FATAL: Insufficient disk space. Available: ${available_mb}MB, required: ${DB_MIN_DISK_MB}MB"
        return 1
    fi
}

# Validate config required by every restic backend
for var in RESTIC_REPOSITORY RESTIC_PASSWORD; do
    if [[ -z "${!var}" ]]; then
        log_message "FATAL: $var is not set in Config.sh"
        echo "FATAL: $var is not set in Config.sh" >&2
        exit 1
    fi
done

# S3 repositories require AWS credentials. Other backends validate their own
# credentials and connectivity through restic during the pre-flight check.
if [[ "$RESTIC_REPOSITORY" == s3:* ]]; then
    for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY; do
        if [[ -z "${!var}" ]]; then
            log_message "FATAL: $var is not set in Config.sh for S3 repository"
            echo "FATAL: $var is not set in Config.sh for S3 repository" >&2
            exit 1
        fi
    done
fi

command -v restic >/dev/null 2>&1 || { log_message "FATAL: restic not found in PATH"; echo "FATAL: restic not found in PATH" >&2; exit 1; }

# Obtain lock if requested by the calling script
if [[ "${NEEDS_LOCK:-false}" == true ]]; then
    source "$SCRIPTS_ROOT/ObtainLock.sh"
fi

# Global error trap for logging failures
trap 'log_message "FATAL: Script failed at line $LINENO with exit code $?"' ERR

# Enable pipefail globally so piped command failures are not swallowed
set -o pipefail

if [[ "$DRY_RUN" == true ]]; then
    log_message "!!!!!!!DRY RUN ENABLED!!!!!!!"
fi
