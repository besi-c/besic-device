#!/bin/bash
# BESI-C Developer Box On-Device Setup Script
#   https://github.com/pennbauman/besic-device
#   Penn Bauman <pcb8gb@virginia.edu>

LOG="/var/log/besic/setup.log"
DIR="/var/besic"

if [[ $TYPE != "DEVBOX" ]]; then
	echo "[$(date --rfc-3339=seconds)] Unexpected type '$TYPE'" >> $LOG
fi

# Check for internet connection
while true; do
	res=$(curl -sI https://besic.org | head -n 1)
	if [[ $res =~ 200 ]]; then
		break
	fi
done

# Update system packages
apt-get update &>> $LOG
code=$?
if [[ $code != 0 ]]; then
	echo "[$(date --rfc-3339=seconds)] apt-get update failed ($?)" >> $LOG
	exit 1
fi
apt-get -y upgrade &>> $LOG
code=$?
if [[ $code != 0 ]]; then
	echo "[$(date --rfc-3339=seconds)] apt-get upgrade failed ($code)" >> $LOG
	exit 1
fi
apt-get autoremove &>> $LOG
echo "[$(date --rfc-3339=seconds)] Updated Raspberry Pi OS" >> $LOG

# Install packages to setup device
PKGS="libbesic-tools libbesic2-dev besic-router git vim ranger devscripts debhelper"
if [[ -f $DIR/apt-get ]]; then
	PKGS="$PKGS $(cat $DIR/apt-get)"
fi
apt-get -y --no-install-recommends install $PKGS &>> $LOG
code=$?
if [[ $code == 0 ]]; then
	rm -f $DIR/apt-get
else
	echo "[$(date --rfc-3339=seconds)] apt-get install failed ($code)" >> $LOG
	exit 1
fi
echo "[$(date --rfc-3339=seconds)] BESI-C packages installed" >> $LOG

sudo -u pi ssh-keygen -q -f /home/pi/.ssh/id_rsa -N ""
sudo -u pi git clone https://github.com/pennbauman/besic-scripts /home/pi/scripts
sudo -u pi git clone https://github.com/pennbauman/besic-sensors /home/pi/sensors
sudo -u pi git clone https://github.com/pennbauman/libbesic /home/pi/libbesic

echo "[$(date --rfc-3339=seconds)] System setup complete" >> $LOG

exit 0
