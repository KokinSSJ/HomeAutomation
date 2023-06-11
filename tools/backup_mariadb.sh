#!/bin/bash
#set -x 

echo "MariaDB backup started"

date

TOKEN=`cat /ssd/home-assistant/secrets.yaml | grep MARIADB_URL | sed 's/.*://' | sed 's/@.*//' | xargs`

#echo $TOKEN

BACKUP_TIME=$(date '+%Y-%m-%d_%H-%M')
echo $BACKUP_TIME

docker exec mariadb bash -c "mysqldump -u homeassistant -p$TOKEN --all-databases | gzip > /backups/database_$BACKUP_TIME.sql.gz"

date

echo "MariaDB backup done"
#set +x
