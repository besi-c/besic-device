#!/bin/bash
# BESI-C Relay Auto-Updater
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

dir="/var/besic/"

cd $dir/relay-git
git pull --ff-only

cp $dir/relay-git/heartbeat.sh $dir
cp $dir/relay-git/beacon.sh $dir
cp $dir/relay-git/update.sh $dir
cp $dir/relay-git/urls.toml $dir
crontab $dir/relay-git/crontab

apt update
apt -y upgrade

reboot
