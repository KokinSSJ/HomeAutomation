This is project of Home Automation build upon Raspberry Pi 3B.

This can be taken as template for other houses.

Setup with docker-compose.

Using:
 - Home Assistant - hass.io
 - MariaDB as recorder database
 - NodeRED as automation
 - Mosquitto - MQTT broker
 - InfluxDB - time-series database
 - Grafana - visualization of time-series database
 - Zigbee2mqtt - Zigbee integration
 - VSCode - viewing HA configuration without SSH
 - Cloudflared - connection to server from Internet without port forwarding
 
Check out also .env-template. This is only template without any passwords or token, you need to provide those data and rename file to .env 

There is also test.home_automation.yaml which is setup test environment. 
Notice!!! There is no specific network in prod and test setups so there is access between services. 
This is sometimes useful, e.g. migration from SQLite to MariaDB.

Installed HACS via docker directly to volume
https://hacs.xyz/docs/setup/download
1) docker exec -it hass.io bash
2) wget -O - https://get.hacs.xyz | bash -
*) this can be done from two reasons 1. there is volume and 2. volume is connected to SSD storage
---
# MariaDB setup
#mariadb-setup
---
Notice that below is also description when you want to migrate from SQLite to MariaDB database.
1. Provide passwords in .env for MYSQL_ROOT_PASSWORD and HA_MYSQL_PASSWORD.
2. Adjust Home Assistant /ssd/home-assistant/configuration.yaml
```yaml
recorder:
  db_url: !secret MARIADB_URL
```
3. Add MARIADB_URL to /ssd/home-assistant/secrets.yaml and replace HA_MYSQL_PASSWORD with real value from step 1.
```yaml
MARIADB_URL: mysql://homeassistant:<HA_MYSQL_PASSWORD>@mariadb/ha_db?charset=utf8mb4
```
4. Restart HA -> docker restart hass.io
---
# Przydatne MariaDB
select count(*), now(), DATE(FROM_UNIXTIME(last_updated_ts)) as last_upd from states group by last_upd;
select count(*) as cnt, now(), DATE(FROM_UNIXTIME(last_updated_ts)) as last_upd, metadata_id from states group by last_upd, metadata_id order by cnt desc limit 50;
select count(*) as cnt, now(), DATE(FROM_UNIXTIME(last_updated_ts)) as last_upd, metadata_id from states group by metadata_id order by cnt desc limit 50;
---
Backup
---
1. `docker exec -it mariadb bash`
2. `mysqldump -u homeassistant -p<HA_MYSQL_PASSWORD> --all-databases | gzip > /backups/database_`date '+%Y-%m-%d'`.sql.gz` Notice there is no space after -p and before password

To automate backups I put above to script /tools/backup_mariadb.sh and added to crontab
`sudo crontab -e`
`0 2 * * 1 /ssd/HomeAutomation/tools/backup_mariadb.sh >> /ssd/backups/mariadb/backup_mariadb.log 2>&1` 1:30am every Monday
---
Connecting to Mariadb
`mysql  -u homeassistant -p<HA_MYSQL_PASSWORD> ha_db` or
`docker exec -it mariadb mysql -u homeassistant -p<HA_MYSQL_PASSWORD> ha_db`

Migration of SQLite to MariaDB with setup
---
First disclaimer: This process is describe how to do migration from SQLite to MariaDB and you didn't configure MariaDB in Home Assistant yet. 
If you already have MariaDB and you have old SQLite data which you want to restore (join with current data) this instruction is not for you.

READ STEPS CAREFULLY, some steps might be done in mean time of waiting.

The fewer data to migrate the better. 
Below steps were done on db weighted around 300MB with ~1M states records, ~400k statistics and whole process took around 100minutes.
Database was cleaned via recorder.purge service with repack to left only 1 day of data.
There are two options how we can migrate data with below steps and which might need some small adjustment. 
First is using two environments or at least other HA instance to initialize database.
Second is using one HA instance but as downside with bigger downtime as the same instance will initialize database.
Below steps describe first option with two HA instances.

Steps:
1. We will need SQLite3 in version at least 3.35.0 as we need to remove some columns before migration.
   * As Raspberry Pi 3B with Raspbian the latest version of sqlite3 is 3.34.0, we need other system with sqlite3 3.35.0+ or we can make sqlite3 with the latest version.
      Second solution allow for less downtime as we don't need to transfer database back and forth.
      Building sqlite3 on Raspberry Pi 3 took around 90min, so even more time-consuming but doesn't affect downtime after all.
      Link to SQLite3 binaries: https://www.sqlite.org/download.html
      For installation I've followed : https://linuxhint.com/install-set-up-sqlite-raspberry-pi/
   * Verify version by `sqlite3 --version`
2. SQLite viewer for verification e.g. https://sqlitebrowser.org/
3. Install migration tool `sqlite3-to-mysql`: https://github.com/techouse/sqlite3-to-mysql
4. Start MariaDB (from home_automation.yaml) - check logs if all created and noe issues. Check [MariaDB setup](#mariadb-setup) section.
5. Start test Home Assistant with "prod to be" MariaDB
   1. Adjust secrets.yaml and configuration.yaml of test.home-assistant/ as described in [MariaDB setup](#mariadb-setup) .
   2. Start test Home Assistant and let it start and run for few minutes to create MariaDB structure.
   3. You can also verify if structure is ready by connecting to database e.g. with DBeaver.
   4. When structure is ready you can stop test Home Assistant instance.
6. Clear all database data created - we are going to restore everything from prod Home Assistant instance.
```roomsql
-- clear everything below
delete from events;
select count(*) from events;
delete from event_data;
select count(*) from event_data;
delete from recorder_runs ;
select count(*) from recorder_runs;
delete from schema_changes; 
select count(*) from schema_changes;
delete from statistics;
select count(*) from statistics;
delete from statistics_meta ;
select count(*) from statistics_meta;
delete from statistics_runs ;
select count(*) from statistics_runs;
delete from statistics_short_term ;
select count(*) from statistics_short_term;
-- you should have a problem to run delete from states so we can first remove data.
update states set old_state_id = NULL where old_state_id is not null;
delete from states;
select count(*) from states;
delete from state_attributes;
select count(*) from state_attributes;
```
7. Backup Home Assistant data and copy to safe location.
8. Run service recorder.purge to leave only as much data as you need. I've purge data older than 1day
   (older than 0 days will produce problems with statistics and helpers so don't purge everything)
   and repack SQLite database to send data faster to other server and also reduce downtime.
9. Backup Home Assistant data and copy to safe location - again but after purging data.
10. ---- HERE WE START DOWNTIME -----
11. Stop docker for Home Assistant (and others to lower server load)
12. Make backup of home-assistant_v2.db `cp  home-assistant_v2.db  backup.home-assistant_v2.db`
13. Copy `home-assistant_v2.db` to some temp working folder `cp  home-assistant_v2.db /ssd/sqlite-migration/migrate-home-assistant_v2.db` to work on that copy.
14. Prepare SQLite database for migration.
    1. Run sqlite3 installed earlier on `migrate-home-assistant_v2.db` by `sqlite3 migrate-home-assistant_v2.db`
    2. Remove column `created` from table `events` and `states`
    3. Remove column `domain` from table `steates`
    4. You can verify deletion by `pragma table_info(<table-name>)` to verify list of columns.
```roomsql
sqlite3 home-assistant_v2.db
> pragma table_info(events); -- check before
> alter table events drop column created;
> pragma table_info(events); -- check after
> pragma table_info(states); -- check before
> alter table states drop column domain;
> alter table states drop column created;
> pragma table_info(states); -- check after
> .exit
```
15. Start data migration (adjust <HA_MYSQL_PASSWORD>)
Notice this part can take few hours depends on server computing power and database size.

`sqlite3mysql --sqlite-file migrate-home-assistant_v2.db --mysql-database ha_db --mysql-host localhost --mysql-port 3306 --mysql-user homeassistant --mysql-password <HA_MYSQL_PASSWORD> --ignore-duplicate-keys`
16. Connect to MariaDB and remove additional foreign keys:
Notice: In my setup below FK were created by migration tool and are redundant as similar FK already exists.
```roomsql
-- ALTER TABLE ha_db.states DROP FOREIGN KEY states_FK_0_0;
-- ALTER TABLE ha_db.states DROP FOREIGN KEY states_FK_1_0;
-- ALTER TABLE ha_db.statistics DROP FOREIGN KEY statistics_FK_0_0;
-- ALTER TABLE ha_db.statistics_short_term DROP FOREIGN KEY statistics_short_term_FK_0_0;
```
17. I've additionally compared database auto-increments current value and last id keys (current auto increment value should be higher by 1 than last / the highest id number). 
I've checked auto increment value by generated DDL in DBeaver for each table.
18. I've also compared number of rows between MariaDB and SQLite by running for each table `select count(*) from <table-name>`
19. Adjust secrets.yaml and configuration.yaml for prod Home Assistant to point to MariaDB - same as for test Home Assistant.
20. Start (prod) Home Assistant and verify if everything works - check Home Assistant logs and check if no "recorder" troubles. You can also verify in MariaDB if new data are commited.
21. If you validated that everything works for at least few hours. You can remove `/ssd/home-assistant/home-assistant_v2.db`
22. If something doesn't work, just remove db_url in configuration.yaml and restart Home Assistant.
23. Done :)



---
How to start test HA instance.
1. stop prod HA instance
2. copy folder of /ssd/home-assistant to /ssd/test.home-assistant
3. start prod HA instance from home_automation.yaml compose file
4. start test HA instance from test.home_automation.yaml compose file (notice that paths are adjusted). 
5. Access prod HA via <IP>:8123/ and login with credentials
6. Access test HA via <IP>:8124/ and login with credentials from prod

Notice that you may see data in your test HA because server is connected to common MQTT instance.

---
# InfluxDB

Install
---
1. After starting InfluxDB database, configuring it in Home Assistant:
/ssd/home-assistant/configuration.yaml
```yaml
influxdb:
    api_version: 2
    ssl: false
    host: influxdb
    port: 8086
    bucket: home-automation
    token: !secret INFLUXDB_INIT_ADMIN_TOKEN
    organization: !secret INFLUXDB_ORGANIZATION
    max_retries: 3
    default_measurement: state
    include:
        domains:
          - sensor
```
2. Add secrets INFLUXDB_INIT_ADMIN_TOKEN (generated at first start) and INFLUXDB_ORGANIZATION (same as in compose DOCKER_INFLUXDB_INIT_ORG) 
to /ssd/home-assistant/secrets.yaml
```yaml
INFLUXDB_INIT_ADMIN_TOKEN: <token>
INFLUXDB_ORGANIZATION: db
```

---
Backups
---
1. Login via SSH to server
2. `docker exec -it influxdb bash`
3. `influx backup /backups/backup_$(date '+%Y-%m-%d_%H-%M') -t <INFLUXDB_INIT_ADMIN_TOKEN>`
4. `tar -czvf backup_XXXXXX.tar.gz /ssd/backups/influxdb/backup_XXXX` Where XXXX is name from previous step.

To automate backups I put above to script /tools/backup_influxdb.sh and added to crontab
   `sudo crontab -e`
   `0 1 * * 1 /ssd/HomeAutomation/tools/backup_influxdb.sh >> /ssd/backups/influxdb/backup_influxdb.log 2>&1` 1:00am every Monday



Restore
---
https://docs.influxdata.com/influxdb/v2.6/reference/cli/influx/restore/


------------------------
Loop for pulling images.
---
As pulling images on Raspberry Pi 3B is taking a while it is better to do it not via docker-compose command (docker compose pull take only one parameter / image at the time)
or here by many docker pull one by one in queue.
for img in homeassistant/home-assistant:2023.5.4  linuxserver/mariadb:10.6.13 influxdb:2.7.1 grafana/grafana:9.5.2 nodered/node-red:3.0.2-18 koenkk/zig bee2mqtt:1.31.0 cloudflare/cloudflared:2023.5.1 ; do docker pull $img; done

