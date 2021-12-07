#!/bin/bash
# BESI-C Relay Enable Bluetooth Beacon
#   https://github.com/pennbauman/besic-relay
#   Yudel Martinez <yam3nv@virginia.edu>
#   Penn Bauman <pcb8gb@virginia.edu>

DIR="/var/besic"
LOG="/var/log/besic/beacon.log"

# Get MAC from config
source $DIR/config.conf
if [ -z ${MAC+x} ]; then
	echo "[$(date --rfc-3339=seconds)]: MAC not found" >> $LOG
	exit 1
fi
id=${MAC: -2}

# Configure the bluetooth module
hciconfig hci0 down
hciconfig hci0 up
hciconfig hci0 leadv 3
hciconfig hci0 noscan

# Make bluetooth beacon
hcitool -i hci0 cmd 0x08 0x0008 1E 02 01 1A 1A FF 4C 00 02 15 B9 40 7F 30 F5 F8 46 6E AF F9 25 55 6B 57 FE 6D 00 $id BE 51 C8 00
