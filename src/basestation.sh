#!/bin/bash
# BESI-C Basestation On-Device Setup Script
#   https://github.com/pennbauman/besic-device
#   Penn Bauman <pcb8gb@virginia.edu>

LOG="/var/log/besic/setup.log"
DIR="/var/besic"
TEAMVIEWER_SH="/home/pi/teamviewer.sh"


if [[ $TYPE != "BASESTATION" ]]; then
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
apt-get autoremove
echo "[$(date --rfc-3339=seconds)] Updated Raspberry Pi OS" >> $LOG

# Install packages to setup device
PKGS="libbesic-tools"
	#besic-router
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

echo "#!/bin/bash
# Setup teamviewer

DEB_URL=\"https://download.teamviewer.com/download/linux/teamviewer-host_armhf.deb\"

wget \$DEB_URL -O /tmp/\$(basename \$DEB_URL)
sudo apt-get -y install /tmp/\$(basename \$DEB_URL)

sudo teamviewer setup" > $TEAMVIEWER_SH
chown pi $TEAMVIEWER_SH
chmod +x $TEAMVIEWER_SH


sudo -u pi ssh-keygen -q -f /home/pi/.ssh/id_rsa -N ""

echo "* * * * * besic-heartbeat" | crontab -

echo "[$(date --rfc-3339=seconds)] Device setup complete" >> $LOG
