#!/bin/bash

echo "InfluxDB backup started"

TOKEN=`cat /ssd/home-assistant/secrets.yaml | grep INFLUXDB_INIT_ADMIN_TOKEN | sed 's/INFLUXDB_INIT_ADMIN_TOKEN:*//g'| xargs`

#echo $TOKEN

BACKUP_TIME=$(date '+%Y-%m-%d_%H-%M')
echo $BACKUP_TIME

# no '-it' as it runs in crontab
docker exec influxdb influx backup /backups/backup_$BACKUP_TIME -t $TOKEN

sudo tar -czvf /ssd/backups/influxdb/backup_$BACKUP_TIME.tar.gz /ssd/backups/influxdb/backup_$BACKUP_TIME

sudo rm -rf /ssd/backups/influxdb/backup_$BACKUP_TIME/

echo "InfluxDB backup done"