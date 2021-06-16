#!/bin/bash
# BESI-C Relay Heartbeat
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

url="http://dev.remote.besic.org"
log="/var/log/besic/heartbeat.log"

mkdir -p $(dirname $log)

dir="/var/besic"
config="$dir/config.toml"

id=$(tq .mac $config)
if (($? != 0)); then
	echo "Config error"
	exit 1
fi

fail=0
i=0
while (( $i < 9 )); do
	curl "$url/api/device/$id/heartbeat"
	if (( $? != 0 )); then
		fail=$(($fail + 1))
	fi
	sleep 5
	i=$(($i + 1))
done

if (($fail > 1)); then
	echo "[$(date)] $fail heartbeats failed" >> $log
elif (($fail > 0)); then
	echo "[$(date)] 1 heartbeat failed" >> $log
else
	if [[ -f $log ]]; then
		tail -n 100 $log > ${log}.temp
		mv ${log}.temp $log
	fi
fi

