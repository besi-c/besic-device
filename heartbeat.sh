#!/bin/bash
# BESI-C Relay Heartbeat
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

url="http://dev.remote.besic.org"
log="/var/log/besic/heartbeat.log"

dir="/var/besic"
config="$dir/config.toml"

if [ ! -f $config ]; then
	echo "Missing config"
	exit 1
fi

id=$(cat $config | grep "mac =" | sed 's/.*= //')

i=0
while (( $i < 9 )); do
	curl "$url/api/device/$id/heartbeat"
	if (( $? == 0 )); then
		exit 0
	fi
	i=$(($i + 1))
done

echo "[$(date)] heartbeat failed" >> $log
tail -n 100 $log > ${log}.temp
mv ${log}.temp $log

