#!/bin/bash
# BESI-C Relay Heartbeat
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

dir="/var/besic"
log="/var/log/besic/heartbeat.log"


url=$(tq .remote $dir/urls.toml)
if (($? != 0)); then
	echo "[$(date --rfc-3339=seconds)]: Url not found (remote)" >> $log
	exit 1
fi

id=$(tq .mac $dir/config.toml)
if (($? != 0)); then
	echo "[$(date --rfc-3339=seconds)]: Config not found (mac)" >> $log
	exit 1
fi
password=$(tq .password $dir/config.toml)
if (($? != 0)); then
	echo "[$(date --rfc-3339=seconds)]: Config not found (password)" >> $log
	exit 1
fi


fail=0
i=0
while (( $i < 9 )); do
	curl "$url/api/device/$id/heartbeat" -d "password=$password"
	if (( $? != 0 )); then
		fail=$(($fail + 1))
	fi
	sleep 5
	i=$(($i + 1))
done

if (($fail > 1)); then
	echo "[$(date --rfc-3339=seconds)] $fail heartbeats failed" >> $log
elif (($fail > 0)); then
	echo "[$(date --rfc-3339=seconds)] 1 heartbeat failed" >> $log
else
	if [[ -f $log ]]; then
		tail -n 100 $log > ${log}.temp
		mv ${log}.temp $log
	fi
fi

