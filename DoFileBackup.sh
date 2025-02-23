# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

echo "Backing up files defined in INCLUDE_FILE..."

restic backup --iexclude-file=$RESTIC_EXCLUDE_FILE --files-from=$RESTIC_INCLUDE_FILE --read-concurrency 10 --option s3.connections=8 --compression max $RESTIC_DRY_RUN_OPTION

echo "Done"