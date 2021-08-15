#!/bin/bash
# BESI-C Relay On-Device Setup Script
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

dir="/var/besic"
git="$dir/relay-git"
log="/var/log/besic/init.log"
mkdir -p $(dirname $log)

if [ -f $dir/passwd ]; then
	cat $dir/passwd | tee -a $dir/passwd
	passwd pi < $dir/passwd
	rm $dir/passwd
	echo "[$(date --rfc-3339=seconds)]: Password updated" >> $log
fi

read mac < /sys/class/net/wlan0/address
mac="$(echo ${mac:9} | sed 's/://g')"
password=$(openssl rand -hex 32)

hostname="besic-relay-$mac"
echo "$hostname" > /etc/hostname
echo "127.0.0.1 $hostname" > /etc/hosts

echo "MAC=\"$mac\"" > $dir/config.conf
echo "PASSWORD=\"$password\"" >> $dir/config.conf

cp $git/install/update.sh $dir
cp $git/heartbeat.sh $dir
cp $git/beacon.sh $dir
cp $git/urls.conf $dir
crontab $git/crontab

source $dir/urls.conf
if [ -z ${REMOTE_URL+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: REMOTE_URL not found" >> $log
	exit 1
fi

while true; do
	res=$(curl "$REMOTE_URL/api/device/new" -d "mac=$mac&type=relay&password=$password")
	if [[ $res == "Success" ]]; then
		break
	fi
	echo "[$(date --rfc-3339=seconds)]: Remote init failed ($res)" >> $log
	sleep 5
done

echo "[$(date --rfc-3339=seconds)]: Setup complete" >> $log

echo "apt update; apt -y upgrade; rm $dir/init.sh" > $dir/init.sh

reboot
