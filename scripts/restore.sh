#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo " Usage: ./restore.sh <backup-file>"
  exit 1
fi

echo "♻️ Restoring MySQL backup..."

cat $1 | docker exec -i skillpulse-mysql-1 \
  mysql -u root -p${MYSQL_ROOT_PASSWORD} skillpulse

echo "Restore completed!"
