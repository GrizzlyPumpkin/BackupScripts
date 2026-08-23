## Setup

1. Copy all scripts to a known location
2. Set permissions:
    - `chmod 700 *.sh` for all scripts
    - `chmod 600 Config.sh DB.cnf` for files containing credentials
3. Copy `Config.sh.example` to `Config.sh` and fill in your values. Copy `DB.cnf.example` to `DB.cnf` and update password, if needed
4. Update config based on needed features and repository type. Restic selects the backend from `RESTIC_REPOSITORY`; no separate backend setting is needed. Examples:
    - S3: `export RESTIC_REPOSITORY="s3:s3.example.com/bucket/path"`
    - Backblaze S3-compatible storage: `export RESTIC_REPOSITORY="s3:repo"`
    - SFTP with an absolute path: `export RESTIC_REPOSITORY="sftp:user@host:/srv/restic-repo"`
    - SFTP with a path relative to the remote user's home: `export RESTIC_REPOSITORY="sftp:host:backups/restic"`
    - Local directory: `export RESTIC_REPOSITORY="/srv/restic-repo"`
    - Other Restic backends, such as REST, B2, Azure, and rclone, can use their standard repository strings and credential environment variables in `Config.sh`.
5. If using Backblaze, ensure the key is scoped to the bucket and client folder
6. Install restic from the pre-compiled binary
    1. From github download bz2 release
    2. Use `bzip2 -d restic-X.bz2` to extract
    3. Rename to restic
    4. `chmod +x`
    5. Move to `/usr/bin/restic`
7. Run `./ResticWrapped.sh init` to setup repo
8. Verify emails are able to be sent on server by installing mailutils
9. Setup cron based on the schedule below, ensuring MAILTO is defined

### SFTP Setup

SFTP repositories use the SSH configuration of the account that runs the backup cron job. The server must have `ssh` installed and that account must have non-interactive public-key authentication to the repository host, the remote host key in its `known_hosts` file, and permission to read and write the repository directory.

Test the SSH connection as the cron account before running `./ResticWrapped.sh init`. The scripts do not manage SSH passwords, keys, or host-key verification.

## File Structure

- **`Config.sh`** — Server-specific settings only (credentials, ping URLs, DB config). This is the only file that needs editing per server. Gitignored.
- **`Init.sh`** — Shared initialisation logic (logging, validation, locking, error handling). Tracked in git. Do not edit on servers — updates come via `git pull`.
- **`Config.sh.example`** — Template for creating `Config.sh`.

## Cron Config
```
MAILTO=email@domain.com

# Backups
## Daily Backup - 4am
0 4 * * * /path/to/BackupScripts/DoFullBackup.sh 2>&1

## Weekly Forget and Prune - 11pm Fridays
0 23 * * 5 /path/to/BackupScripts/CleanOldSnapshots.sh 2>&1

## Monthly Integrity Check - 2am 1st
0 2 1 * * /path/to/BackupScripts/DoIntegrityCheck.sh 2>&1
```

## Logrotate

The scripts log to `/var/log/pumpkin/backups.log`. Configure logrotate to prevent unbounded growth. Create `/etc/logrotate.d/pumpkin-backups`:
```
/var/log/pumpkin/*.log {
        daily
        missingok
        rotate 2
        compress
        notifempty
        minsize 5M
}
```

## Email Alerts

Cron's `MAILTO` provides a secondary alerting mechanism. Any output to stderr (e.g. from a failed command) will be emailed. Verify email delivery is working on each server by installing `mailutils` and testing with:
```
echo "Test" | mail -s "Cron test" your@email.com
```

## Pre-flight Checks

Before each run, the entry-point scripts perform pre-flight checks:
- **Repository connectivity** — verifies the restic repository is reachable and credentials work. Runs before DoFullBackup, CleanOldSnapshots, and DoIntegrityCheck.
- **Disk space** — verifies sufficient free space for the SQL dump (default 2GB minimum, configurable via `DB_MIN_DISK_MB` in Config.sh). Only runs when `DB_BACKUP=true`.

If any pre-flight check fails, the script sends a `/fail` ping to the relevant healthchecks.io endpoint for immediate alerting, then exits. Any other failure during the backup also triggers a `/fail` ping via an EXIT trap.

## Locking

The scripts use `flock` to prevent concurrent runs. The lock file is at `/var/lock/doing_server_backup`. Only scripts that modify the repository (DoFullBackup, CleanOldSnapshots, DoIntegrityCheck) acquire the lock. `ResticWrapped.sh` does not lock, so read-only commands like `snapshots` or `ls` work while a backup is running.

If backups stop running, check if a previous process is still holding the lock:
```
fuser /var/lock/doing_server_backup
```

## Dry Run

Set `DRY_RUN=true` in Config.sh or pass it via environment variable:
```
DRY_RUN=true ./DoFullBackup.sh
```

## Restoring
1. Identify snapshot with files to restore using `./ResticWrapped.sh snapshots`
2. List files in snapshot `./ResticWrapped.sh ls --long $SNAPSHOTID <optional path>`
3. Restore whole snapshot to another location `./ResticWrapped.sh restore --target=/new/path $SNAPSHOT_ID`
4. Restore specific files from a snapshot `./ResticWrapped.sh restore --target=/new/path --include=X $SNAPSHOT_ID`

## Migrating from older versions

If upgrading from a version where `Config.sh` contained both config and logic:
1. `git pull` to get the new files including `Init.sh`
2. Edit your existing `Config.sh` and remove everything except variable declarations (credentials, ping URLs, DB settings). See `Config.sh.example` for the expected format.
3. `chmod 700 Init.sh`
4. Existing S3 configurations need no changes. For non-S3 repositories, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` may be left empty; export any credentials required by the selected Restic backend from `Config.sh`.
