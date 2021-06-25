#!/bin/bash
# BESI-C Relay On-Device Setup Script
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

dir="/var/besic/"
log="/var/log/besic/init.log"
mkdir -p $(dirname $log)

read mac < /sys/class/net/wlan0/address
mac="$(echo ${mac:9} | sed 's/://g')"
password=$(openssl rand -base64 32)

hostnamectl set-hostname "besic-relay-$mac"
echo "mac = \"$mac\"" > $dir/config.toml
echo "password = \"$password\"" >> $dir/config.toml

cp $dir/relay-git/heartbeat.sh $dir
cp $dir/relay-git/beacon.sh $dir
cp $dir/relay-git/urls.toml $dir
crontab $dir/relay-git/crontab

url=$(tq .remote $dir/urls.toml)
if (($? != 0)); then
	echo "[$(date --rfc-3339=seconds)]: Url not found (remote)" >> $log
	exit 1
fi
while true; do
	res=$(curl "$url/api/device/new" -d "mac=$mac&type=relay&password=$password")
	if (( $? == 0 )); then
		break
	fi
	echo "[$(date --rfc-3339=seconds)]: Remote init failed ($res)" >> $log
done

echo "[$(date --rfc-3339=seconds)]: Setup complete" >> $log

echo "apt update; apt -y upgrade; rm $dir/init.sh" > $dir/init.sh

reboot
