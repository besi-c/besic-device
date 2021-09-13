#!/bin/bash
# BESI-C Relay Auto-Updater
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

DIR="/var/besic"
GIT_DIR="$DIR/relay-git"

source $DIR/config.conf
if [ -z ${MAC+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: MAC not found" >> $log
	exit 1
fi
if [ -z ${PASSWORD+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: PASSWORD not found" >> $log
	exit 1
fi

source $DIR/urls.conf
if [ -z ${REMOTE_URL+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: REMOTE_URL not found" >> $log
	exit 1
fi

# Update deployment info
curl "$REMOTE_URL/api/device/$MAC/deployment" -d "password=$PASSWORD" > /tmp/deploy.conf
if [[ $(cat /tmp/deploy.conf) =~ DEPLOYMENT ]]; then
	mv /tmp/deploy.conf $DIR/deploy.conf
fi
systemctl restart besic.sensors.service


# Daily more complex updates
if [[ $1 == "daily" ]]; then
	cd $GIT_DIR
	git pull --ff-only

	cp $GIT_DIR/scripts/heartbeat.sh $DIR
	cp $GIT_DIR/scripts/beacon.sh $DIR
	cp $GIT_DIR/scripts/s3-uploader.py $DIR
	cp $GIT_DIR/scripts/upload.sh $DIR
	cp $GIT_DIR/urls.conf $DIR
	crontab $GIT_DIR/crontab

	echo "cp $GIT_DIR/install/update.sh $DIR; rm $DIR/init.sh" > $DIR/init.sh
	reboot
fi
