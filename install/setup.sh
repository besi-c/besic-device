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
mac="$(echo $mac | sed 's/://g')"
password=$(openssl rand -hex 32)

hostname="besic-relay-${mac:6}"
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

# Set time from remote server
timedatectl set-timezone America/New_York
while true; do
	time=$(curl -s "$REMOTE_URL/time/iso" | sed 's/\....Z//' | sed 's/"//g' | sed 's/T/ /')
	timedatectl set-time $time
	echo "? = $? : time = $time" >> $LOG
	#date +%Y-%m-%dT%TZ -s $time
	if (( $? == 0 )); then
		hwclock -w
		echo "[$(date --rfc-3339=seconds)]: Time set complete" >> $LOG
		break
	fi
	echo "[$(date --rfc-3339=seconds)]: Time set failed" >> $LOG
	sleep 5
done

# Initialize relay on remote server
while true; do
	res=$(curl -s "$REMOTE_URL/device/new?mac=$mac&password=$password&type=RELAY")
	if [[ $res == "Success" ]]; then
		curl -s "$REMOTE_URL/device/deployment?mac=$mac&password=$password" > $DIR/deploy.conf
		echo "[$(date --rfc-3339=seconds)]: Remote init complete" >> $LOG
		break
	fi
	echo "[$(date --rfc-3339=seconds)]: Remote init failed ($res)" >> $LOG
	sleep 5
done

# Install python modules for uploader
apt update
apt -y install python3-pip git
pip3 install boto3

echo "bash /var/besic/sensors/install.sh; rm $DIR/init.sh" > $DIR/init.sh

echo "[$(date --rfc-3339=seconds)]: Setup complete" >> $LOG

reboot
