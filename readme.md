## Setup

1. Copy all scripts to a known location
2. chmod all scripts
3. Update config based on needed features/repository
    1. Example Backblaze repo string export RESTIC_REPOSITORY="s3:s3.eu-central-003.backblazeb2.com/grizzly-pumpkin-client-backups/CLIENT/OPTIONAL_FOLDER"
4. If using backblaze, ensure the key is scoped to the bucket and client folder
5. Install restic from the pre-compiled binary
    1. From github download bz2 release
    2. Use bzip2 -d restic-X.bz2 to extract
    3. Rename to restic
    4. Chmod +x
    5. Move to /usr/bin/restic
6. Copy Config.sh.example to Config.sh and update. Copy DB.cnf.example to DB.cnf and update password, if needed
7. Run ./ResticWrapped.sh init to setup repo
8. Verify emails are able to be sent on server by installing mailutils
9. Setup cron based on the schedule below, ensuring MAIL_TO is defined

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

## Restoring
1. Identify snapshot with files to restore using `./ResticWrapped.sh snapshots`
2. List files in snapshot `./ResticWrapped.sh ls --long $SNAPSHOTID <optional path>`
3. Restore whole snapshot to another location `./ResticWrapped.sh restore --target=/new/path $SNAPSHOT_ID`
4. Restore specific files from a snapshot `./ResticWrapped.sh restore --target=/new/path --include=X $SNAPSHOT_ID`