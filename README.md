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
