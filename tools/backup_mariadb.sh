#!/bin/bash

echo "MariaDB backup started"

TOKEN=`cat /ssd/home-assistant/secrets.yaml | grep MARIADB_URL | sed 's/.*://' | sed 's/@.*//' | xargs`

echo $TOKEN

BACKUP_TIME=$(date '+%Y-%m-%d_%H-%M')
echo $BACKUP_TIME

docker exec mysqldump -u homeassistant -p$TOKEN --all-databases | gzip > /backups/database_`date '+%Y-%m-%d'`.sql.gz

echo "MariaDB backup done"
