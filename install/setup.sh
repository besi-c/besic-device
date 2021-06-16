#!/bin/bash
# BESI-C Relay On-Device Setup Script
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

dir="/var/besic/"

read mac < /sys/class/net/wlan0/address
mac="$(echo ${mac:9} | sed 's/://g')"
hostnamectl set-hostname "besic-relay-$mac"
echo "mac = \"$mac\"" > $dir/config.toml

mkdir -p /var/log/besic/

cp $dir/relay-git/heartbeat.sh $dir
cp $dir/relay-git/beacon.sh $dir
crontab $dir/relay-git/crontab
rm $dir/init.sh

apt update
apt upgrade

reboot
