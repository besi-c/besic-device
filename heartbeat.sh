#!/bin/bash
# BESI-C Relay Heartbeat
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

url="http://dev.remote.besic.org"
log="/var/log/besic/heartbeat.log"

dir="/var/besic"
config="$dir/config.toml"

if [ ! -f $config ]; then
	read mac < /sys/class/net/wlan0/address
	mac="$(echo ${mac:9} | sed 's/://g')"
	echo "id = $mac" > $config
fi

id=$(cat $config | grep "id =" | sed 's/.*= //')

i=0
while (( $i < 9 )); do
	curl "$url/api/relay/$id/heartbeat"
	if (( $? == 0 )); then
		exit 0
	fi
	i=$(($i + 1))
done

echo "[$(date)] heartbeat failed" >> $log
tail -n 100 $log > ${log}.temp
mv ${log}.temp $log

