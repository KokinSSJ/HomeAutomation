This is project of Home Automation build upon Raspberry Pi 3B.

Setup with docker-compose.

Using:
 - Home Assistant - hass.io
 - NodeRED
 - Moquitto MQTT
 

Adding seperate check for SpeedTest and loading to InfluxDB
-> In future replace with HomeAssistant integration

Installed HACS via docker directly to volume
https://hacs.xyz/docs/setup/download
1) docker exec -it hass.io bash
2) wget -O - https://get.hacs.xyz | bash -
*) this can be done from two reasons 1. there is volume and 2. volume is connected to SSD storage



Configuring InfluxDB in Home Assistant:
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

