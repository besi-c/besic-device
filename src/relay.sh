#!/bin/bash
# BESI-C Relay On-Device Setup Script
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

LOG="/var/log/besic/setup.log"
DIR="/var/besic"
TMP_DIR=$(mktemp -d)


if [[ $TYPE != "RELAY" ]]; then
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
	echo "[$(date --rfc-3339=seconds)] apt-get update failed ($code)" >> $LOG
	exit 1
fi
# Update if available
if [[ $(apt-get -s upgrade -V | grep '=>' | wc -l) != 0 ]]; then
	apt-get -y upgrade &>> $LOG
	code=$?
	if [[ $code != 0 ]]; then
		echo "[$(date --rfc-3339=seconds)] apt-get upgrade failed ($code)" >> $LOG
		exit 1
	fi
	echo "[$(date --rfc-3339=seconds)] Updated Raspberry Pi OS" >> $LOG
	reboot
fi

# Install snd-i2smic-rpi
apt-get -y install raspberrypi-kernel-headers dkms git &>> $LOG
code=$?
if [[ $code != 0 ]]; then
	echo "[$(date --rfc-3339=seconds)] apt-get install dkms failed ($code)" >> $LOG
	exit 1
fi
dkms add -m snd-i2s_rpi -v 0.1.0 &>> $LOG
dkms build -m snd-i2s_rpi -v 0.1.0 &>> $LOG
dkms install -m snd-i2s_rpi -v 0.1.0 &>> $LOG
echo "[$(date --rfc-3339=seconds)] snd-i2smic-rpi installed" >> $LOG

# Configure snd-i2smic-rpi
GEN_ID="1"
if [[ $(lscpu) =~ 'ARM1176' ]]; then
	GEN_ID="0"
fi
echo "options snd-i2smic-rpi rpi_platform_generation=$GEN_ID" >> /etc/modprobe.d/snd-i2smic-rpi.conf
echo "[$(date --rfc-3339=seconds)] snd-i2smic-rpi configured ($GEN_ID)" >> $LOG


# Install packages to setup device
echo jackd2 jackd/tweak_rt_limits boolean false | debconf-set-selections
PKGS="besic-beacon besic-remote besic-s3upload besic-audio-py besic-envsense"
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
