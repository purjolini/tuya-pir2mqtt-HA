
#!/bin/sh
# Micro seconds between checks
WATCHDOG_SLEEP_SEC=500000
# Seconds between availability payloads
WATCHDOG_AVAILABILITY_SEC=120
# Seconds between autodiscovery payloads
WATCHDOG_CONFIG_SEC=600

# MQTT SETTINGS
BROKER="192.168.0.1"
PORT="1883"
USER=""
PASSWORD=""
TOPIC="homeassistant/binary_sensor"
#CLIENT_ID=""
#LOGFILE="" 

# WIFI SETTINGS
# NIC ex eth2
# 5Ghz NIC
#NIC="eth2"
# 2.4Ghz NIC
NIC2="eth1"

# WIFI TRACK DEVICES
# MAC Address 1. Use capital letters here for adress.
# DEVICE1
NAME_1="bathroom_rqtt"
MAC_ADDRESS_1="XX:XX:XX:XX:XX:XX"
# DEVICE2
NAME_2="kitchen_rqtt"
MAC_ADDRESS_2="XX:XX:XX:XX:XX:XX"

# HA Auto discovery setting
# Default prefix is homeassistant
PREFIX="homeassistant"
# Availability_topic
AVTOPIC="asus-router"

# Register Devices for you in HA
# Make variables to pass json
DEVICE1='{"name":"'$NAME_1'","unique_id":"RQ:'$MAC_ADDRESS_1'","state_topic":"'$PREFIX'/binary_sensor/'$NAME_1'","payload_on":"on","payload_off":"off","device_class":"motion","availability_topic":"'$AVTOPIC'/available"}'
DEVICE2='{"name":"'$NAME_2'","unique_id":"RQ:'$MAC_ADDRESS_2'","state_topic":"'$PREFIX'/binary_sensor/'$NAME_2'","payload_on":"on","payload_off":"off","device_class":"motion","availability_topic":"'$AVTOPIC'/available"}'

# Publish devices to HA for autodiscovery
mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "$DEVICE1" -t $PREFIX/binary_sensor/$NAME_1/config
mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "$DEVICE2" -t $PREFIX/binary_sensor/$NAME_2/config
while sleep $WATCHDOG_CONFIG_SEC
do 
mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "$DEVICE1" -t $PREFIX/binary_sensor/$NAME_1/config
mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "$DEVICE2" -t $PREFIX/binary_sensor/$NAME_2/config
done &

# Availability for HA
while sleep $WATCHDOG_AVAILABILITY_SEC
do
mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "online" -t $AVTOPIC/available
done &

#This loop will check if a device is registered on the AP and send on/off to MQTT.
while usleep $WATCHDOG_SLEEP_SEC
do
# WIFI Checks
if wl -i $NIC2 assoclist | grep -Fq $MAC_ADDRESS_1
then
    #echo Wifi $NAME_1 is connected 2.4Ghz $(date '+%H:%M:%S:%s')
    mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "on" -t $TOPIC/$NAME_1
    sleep 10
else
    #echo Wifi $NAME_1 is not connected 
    mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "off" -t $TOPIC/$NAME_1
fi
done &

while usleep $WATCHDOG_SLEEP_SEC
do
if wl -i $NIC2 assoclist | grep -Fq $MAC_ADDRESS_2
then
    #echo Wifi $NAME_2 is connected 2.4Ghz $(date '+%H:%M:%S:%s')
    mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "on" -t $TOPIC/$NAME_2
    sleep 10
else
    #echo Wifi $NAME_2 is not connected
    mosquitto_pub -u $USER -P $PASSWORD -h $BROKER -m "off" -t $TOPIC/$NAME_2
fi

done
#& Uncomment to run in background
