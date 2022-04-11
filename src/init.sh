#!/bin/bash
# BESI-C On-Device Setup Script
#   https://github.com/pennbauman/besic-device
#   Penn Bauman <pcb8gb@virginia.edu>

LOG="/var/log/besic/init.log"
DIR="/var/besic"
TYPE_CONF="/etc/besic/type.conf"
SETUP_SH="$DIR/setup.sh"
mkdir -p $(basename LOG)


device-type () {
	# Check if device type is already set
	if [ ! -z ${TYPE+x} ]; then
		exit 0
	fi
	# Get device type
	if [ ! -f $TYPE_CONF ]; then
		echo "[$(date --rfc-3339=seconds)] Missing $TYPE_CONF" >> $LOG
		exit 1
	fi
	source $TYPE_CONF
	if [[ $TYPE == "RELAY" ]] || [[ $TYPE == "BASESTATION" ]] || [[ $TYPE == "DEVBOX" ]]; then
		echo "[$(date --rfc-3339=seconds)] Loaded type '$TYPE'" >> $LOG
	elif [[ $TYPE == "" ]]; then
		echo "[$(date --rfc-3339=seconds)] $TYPE_CONF missing TYPE" >> $LOG
		exit 1
	else
		echo "[$(date --rfc-3339=seconds)] Invalid type '$TYPE'" >> $LOG
		exit 1
	fi
}


# Change default password;
if [ -f $DIR/passwd ]; then
	cat $DIR/passwd | tee -a $DIR/passwd > /dev/null
	passwd pi < $DIR/passwd &> /dev/null
	rm $DIR/passwd
	echo "[$(date --rfc-3339=seconds)] Password updated" >> $LOG
fi

# Set time zone and locale
timedatectl set-timezone America/New_York
if [[ $(grep "^en_US" /etc/locale.gen | wc -l) == 0 ]]; then
	sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen &>> $LOG
	locale-gen en_US.UTF-8 &>> $LOG
	update-locale en_US.UTF-8 &>> $LOG
	echo "[$(date --rfc-3339=seconds)] Locale set 'en_US.UTF-8'" >> $LOG
fi

# Set device name
if [[ $(cat /etc/hostname) == "raspberrypi" ]]; then
	device-type
	if [[ $? != 0 ]]; then
		exit 1
	fi

	# Setup device name with mac
	mac="$(sed 's/://g' /sys/class/net/wlan0/address)"
	hostname="besic-$(echo $TYPE | tr A-Z a-z)-${mac:6}"
	echo "$hostname" > /etc/hostname
	sed -i "s/raspberrypi/$hostname/" /etc/hosts
	echo "[$(date --rfc-3339=seconds)] Set hostname" >> $LOG
	reboot
fi

# Run custom setup script if present
if [[ -f $SETUP_SH ]]; then
	device-type
	if [[ $? != 0 ]]; then
		exit 1
	fi
	export TYPE="$TYPE"

	# Run script
	chmod +x $SETUP_SH
	$SETUP_SH >> $LOG
	code=$?
	if [[ $code == 0 ]]; then
		echo "[$(date --rfc-3339=seconds)] $SETUP_SH successful" >> $LOG
		rm $SETUP_SH
	else
		echo "[$(date --rfc-3339=seconds)] $SETUP_SH = $code" >> $LOG
		mv $SETUP_SH ${SETUP_SH}_failed
		exit
	fi
	reboot
fi

echo "[$(date --rfc-3339=seconds)] Init complete" >> $LOG
