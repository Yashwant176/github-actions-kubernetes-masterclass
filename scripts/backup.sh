#!/bin/bash

set -e

BACKUP_DIR=backups
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

echo "Creating MySQL backup..."

docker exec skillpulse-mysql-1 \
  mysqldump -u root -p${MYSQL_ROOT_PASSWORD} skillpulse \
  > $BACKUP_DIR/skillpulse-$TIMESTAMP.sql

echo "Backup saved to $BACKUP_DIR/skillpulse-$TIMESTAMP.sql"
