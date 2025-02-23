# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

if [[ "$DO_PARTIAL_REPO_CHECK" == true ]]; then
	echo "Checking $PARTIAL_REPO_CHECK_SUBSET of repository..."
	restic check --read-data-subset=$PARTIAL_REPO_CHECK_SUBSET $RESTIC_DRY_RUN_OPTION
fi