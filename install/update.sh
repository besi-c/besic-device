#!/bin/bash
# BESI-C Relay Auto-Updater
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

DIR="/var/besic"
GIT_DIR="$DIR/relay-git"

cd $GIT_DIR
git pull --ff-only

cp $GIT_DIR/scripts/heartbeat.sh $DIR
cp $GIT_DIR/scripts/beacon.sh $DIR
cp $GIT_DIR/urls.conf $DIR
crontab $GIT_DIR/crontab

apt update
apt -y upgrade

echo "cp $GIT_DIR/install/update.sh $DIR; rm $DIR/init.sh" > $DIR/init.sh

reboot
