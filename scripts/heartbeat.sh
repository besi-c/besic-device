#!/bin/bash
# BESI-C Relay Heartbeat
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

DIR="/var/besic"
LOG="/var/log/besic/heartbeat.log"

source $DIR/config.conf
if [ -z ${MAC+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: MAC not found" >> $LOG
	exit 1
fi
if [ -z ${PASSWORD+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: PASSWORD not found" >> $LOG
	exit 1
fi

source $DIR/urls.conf
if [ -z ${REMOTE_URL+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: REMOTE_URL not found" >> $LOG
	exit 1
fi


fail=0
i=0
while (( $i < 10 )); do
	res=$(curl -s "$REMOTE_URL/device/heartbeat" -d "mac=$MAC" -d "password=$PASSWORD")
	if [[ $res != "Success" ]]; then
		fail=$(($fail + 1))
		if [[ $res == "Unknown device" ]]; then
			curl -s "$REMOTE_URL/device/new" -d "mac=$MAC" -d "password=$PASSWORD" -d "type=RELAY"
		fi
	fi
	sleep 5
	i=$(($i + 1))
done

if (($fail > 1)); then
	echo "[$(date --rfc-3339=seconds)] $fail heartbeats failed ($res)" >> $LOG
elif (($fail > 0)); then
	echo "[$(date --rfc-3339=seconds)] 1 heartbeat failed ($res)" >> $LOG
fi
