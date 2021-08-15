#!/bin/bash
# BESI-C Relay Heartbeat
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

dir="/var/besic"
log="/var/log/besic/heartbeat.log"

source $dir/config.conf
if [ -z ${MAC+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: MAC not found" >> $log
	exit 1
fi
if [ -z ${PASSWORD+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: PASSWORD not found" >> $log
	exit 1
fi

source $dir/urls.conf
if [ -z ${REMOTE_URL+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: REMOTE_URL not found" >> $log
	exit 1
fi


fail=0
i=0
while (( $i < 10 )); do
	res=$(curl "$REMOTE_URL/api/device/$MAC/heartbeat" -d "password=$PASSWORD")
	if [[ $res != "Success" ]]; then
		fail=$(($fail + 1))
		if [[ $res == "Unknown device" ]]; then
			curl "$REMOTE_URL/api/device/new" -d "mac=$MAC&password=$PASSWORD&type=relay"
		fi
	fi
	sleep 5
	i=$(($i + 1))
done

if (($fail > 1)); then
	echo "[$(date --rfc-3339=seconds)] $fail heartbeats failed ($res)" >> $log
elif (($fail > 0)); then
	echo "[$(date --rfc-3339=seconds)] 1 heartbeat failed ($res)" >> $log
fi

