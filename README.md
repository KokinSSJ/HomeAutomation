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


Installed HACS via docker directly to volume
https://hacs.xyz/docs/setup/download
1) docker exec -it hass.io bash
2) wget -O - https://get.hacs.xyz | bash -
*) this can be done from two reasons 1. there is volume and 2. volume is connected to SSD storage
---
MariaDB
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
InfluxDB

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

