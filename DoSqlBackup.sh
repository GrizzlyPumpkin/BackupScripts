#!/bin/bash

# Load config if not already loaded
if [ -z ${SERVER_BACKUP_SCRIPT+x} ]; then source "$(dirname "$0")/Config.sh"; fi

if [[ "$DB_BACKUP" == true ]]; then
   if [[ "$DRY_RUN" == true ]]; then
       echo "Skipping DB dump as we're in a dry run."
   else
       echo "Dumping a gzip of the DB..."

       mysqldump --defaults-file="$DB_PASSWORD_FILE" -h $DB_HOST -P $DB_PORT -u $DB_USER $DB_NAME --force --single-transaction --quick --compact --extended-insert --order-by-primary $DB_EXTRA_OPTIONS | gzip > $DB_FILE

       echo "DB dumped."
   fi
fi