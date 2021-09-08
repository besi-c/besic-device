#!/bin/bash
# BESI-C Relay On-Device Setup Script
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

DIR="/var/besic"
GIT_DIR="$DIR/relay-git"
LOG="/var/log/besic/init.log"
mkdir -p $(dirname $LOG)
mkdir -p $DIR/data

if [ -f $DIR/passwd ]; then
	cat $DIR/passwd | tee -a $DIR/passwd
	passwd pi < $DIR/passwd
	rm $DIR/passwd
	echo "[$(date --rfc-3339=seconds)]: Password updated" >> $LOG
fi

# Setup unique device id
read mac < /sys/class/net/wlan0/address
mac="$(echo ${mac:9} | sed 's/://g')"
password=$(openssl rand -hex 32)

hostname="besic-relay-$mac"
echo "$hostname" > /etc/hostname
echo "127.0.0.1 $hostname" > /etc/hosts

echo "MAC=\"$mac\"" > $DIR/config.conf
echo "PASSWORD=\"$password\"" >> $DIR/config.conf

# Install scripts
cp $GIT_DIR/install/update.sh $DIR
cp $GIT_DIR/scripts/heartbeat.sh $DIR
cp $GIT_DIR/scripts/beacon.sh $DIR
cp $GIT_DIR/scripts/s3-uploader.py $DIR
cp $GIT_DIR/scripts/upload.sh $DIR
cp $GIT_DIR/urls.conf $DIR
crontab $GIT_DIR/crontab

source $DIR/urls.conf
if [ -z ${REMOTE_URL+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: REMOTE_URL not found" >> $LOG
	exit 1
fi

# Initialize relay on remote server
while true; do
	res=$(curl "$REMOTE_URL/api/device/new" -d "mac=$mac&type=relay&password=$password")
	if [[ $res == "Success" ]]; then
		curl "$REMOTE_URL/api/device/$mac/deployment" -d "password=$password" > $DIR/deploy.conf
		break
	fi
	echo "[$(date --rfc-3339=seconds)]: Remote init failed ($res)" >> $LOG
	sleep 5
done

# Install python modules for uploader
apt update
apt -y install python3-pip
pip3 install boto3

echo "[$(date --rfc-3339=seconds)]: Setup complete" >> $LOG

reboot
