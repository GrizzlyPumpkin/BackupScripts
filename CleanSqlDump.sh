#!/bin/bash

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

if [[ "$DB_BACKUP" == true ]]; then
  if [[ "$DRY_RUN" == true ]]; then
      echo "Skipping cleanup as we're in a dry run."
  else
      rm $DB_FILE
      
      echo "DB dump $DB_FILE removed."
  fi
fi