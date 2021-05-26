#!/bin/bash
# BESI-C Relay On-Device Setup Script
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

dir="/var/besic/"

read mac < /sys/class/net/wlan0/address
mac="$(echo ${mac:9} | sed 's/://g')"
echo "besic-relay-$mac" > /etc/hostname
echo "id = $mac" > $dir/config.toml

mkdir -p /var/log/besic/

cp $dir/relay-git/heartbeat.sh $dir
crontab $dir/relay-git/crontab
rm $dir/init.sh

reboot
