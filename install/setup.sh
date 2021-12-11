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

# Setup device name with mac
mac="$(sed 's/://g' /sys/class/net/wlan0/address)"
hostname="besic-relay-${mac:6}"
echo "$hostname" > /etc/hostname
echo "127.0.0.1 $hostname" > /etc/hosts

# Install crontab
crontab $GIT_DIR/crontab

# Set time zone and locale
timedatectl set-timezone America/New_York
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/en_US.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen en_US.UTF-8
update-locale en_US.UTF-8

# Install python modules for uploader
apt-get update 2>> $LOG
apt-get -y upgrade 2>> $LOG
apt-get -y install besic-relay 2>> $LOG

besic-announce
besic-update

cp $DIR/device.conf $DIR/config.conf

echo "bash /var/besic/sensors/install.sh; rm $DIR/init.sh" > $DIR/init.sh

echo "[$(date --rfc-3339=seconds)]: Setup complete" >> $LOG

reboot
