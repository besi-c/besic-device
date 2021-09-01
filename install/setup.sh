#!/bin/bash
# BESI-C Relay On-Device Setup Script
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

DIR="/var/besic"
GIT_DIR="$DIR/relay-git"
LOG="/var/log/besic/init.log"
mkdir -p $(dirname $LOG)

if [ -f $DIR/passwd ]; then
	cat $DIR/passwd | tee -a $DIR/passwd
	passwd pi < $DIR/passwd
	rm $DIR/passwd
	echo "[$(date --rfc-3339=seconds)]: Password updated" >> $LOG
fi

read mac < /sys/class/net/wlan0/address
mac="$(echo ${mac:9} | sed 's/://g')"
password=$(openssl rand -hex 32)

hostname="besic-relay-$mac"
echo "$hostname" > /etc/hostname
echo "127.0.0.1 $hostname" > /etc/hosts

echo "MAC=\"$mac\"" > $DIR/config.conf
echo "PASSWORD=\"$password\"" >> $DIR/config.conf

cp $GIT_DIR/install/update.sh $DIR
cp $GIT_DIR/scripts/heartbeat.sh $DIR
cp $GIT_DIR/scripts/beacon.sh $DIR
cp $GIT_DIR/urls.conf $DIR
crontab $GIT_DIR/crontab

source $DIR/urls.conf
if [ -z ${REMOTE_URL+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: REMOTE_URL not found" >> $LOG
	exit 1
fi

while true; do
	res=$(curl "$REMOTE_URL/api/device/new" -d "mac=$mac&type=relay&password=$password")
	if [[ $res == "Success" ]]; then
		break
	fi
	echo "[$(date --rfc-3339=seconds)]: Remote init failed ($res)" >> $LOG
	sleep 5
done

echo "[$(date --rfc-3339=seconds)]: Setup complete" >> $LOG

echo "apt update; apt -y upgrade; rm $DIR/init.sh" > $DIR/init.sh

reboot
