#!/bin/bash
# Write BESI-C Relay RasPi Image to SD Card
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

final_img="raspios_besic_relay.img"
dir="$(pwd)/$(dirname $BASH_SOURCE)"

if (( $(lsblk -ln | grep disk | grep ^mmc | wc -l) == 1 )); then
	if [ ! -e "$dir/$final_img" ]; then
		bash "$dir/build.sh"
	fi

	disk=$(lsblk -ln | grep disk | grep ^mmc | sed 's/ .*//')
	sudo dd if="$dir/$final_img" of="/dev/$disk" bs=4M status=progress conv=fsync
else
	echo "SD Card for install not found"
fi
