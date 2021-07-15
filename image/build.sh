#!/bin/bash
# Build BESI-C Relay RasPi Image
#   Penn Bauman <pcb8gb@virginia.edu>
#   https://github.com/pennbauman/besic-relay

zip_file="2021-03-04-raspios-buster-armhf-lite.zip"
zip_url="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-03-25/$zip_file"
basic_img="2021-03-04-raspios-buster-armhf-lite.img"
temp_img="raspios_temp.img"
final_img="../besic_relay_raspios.img"

# Setup Directory
hdir="$(pwd)/$(dirname $BASH_SOURCE)/.."
wdir="$(pwd)/$(dirname $BASH_SOURCE)/tmp"
mkdir -p $wdir
cd $wdir

# Get Basic Image
if [ ! -f $zip_file ]; then
	wget $zip_url -O $zip_file
fi
if [ ! -f $basic_img ]; then
	unzip $zip_file
fi
cp $basic_img $temp_img

mount_temp () {
	# Unmount All
	for d in $wdir/mnt*; do
		sudo umount $d &> /dev/null
		sudo rm -rf $d &> /dev/null
	done
	if [[ $1 == 0 ]]; then
		return
	fi

	# Create Mount Point
	sudo umount $wdir/mnt$1 &> /dev/null
	rm -rf $wdir/mnt$1
	mkdir -p $wdir/mnt$1

	# Find Partition Offsets
	data=$(fdisk -l $temp_img | grep $temp_img$1)
	if [[ $data == "" ]]; then
		echo "Partition '$1' not found"
		exit 1
	fi
	offset=$(echo $data | sed "s/$temp_img$1 *//" | sed "s/ .*//")

	# Mount Partition
	if [[ $1 == 1 ]]; then
		sudo mount -o loop,offset=$((512*$offset)),umask=0000 $temp_img $wdir/mnt$1
	elif [[ $1 == 2 ]]; then
		sudo mount -o loop,offset=$((512*$offset)) $temp_img $wdir/mnt$1
	fi
}

mount_temp 1
# Enable SSH
echo "" > $wdir/mnt1/ssh
# Add WiFi Networks
echo "country=US" > $wdir/mnt1/wpa_supplicant.conf
echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" >> $wdir/mnt1/wpa_supplicant.conf
echo "update_config=1" >> $wdir/mnt1/wpa_supplicant.conf

read -p "SSID: " name
read -p "Password: " pass

wpa_passphrase $name $pass >> $wdir/mnt1/wpa_supplicant.conf
sudo sed -i '/#/d' $wdir/mnt1/wpa_supplicant.conf

mount_temp 2
# Setup Init
dir="$wdir/mnt2/var/besic"
sudo mkdir $dir
sudo cp $hdir/install/init.sh $wdir/mnt2/etc/rc.local
sudo cp $hdir/tq/tq.arm $wdir/mnt2/bin/tq
echo "bash /var/besic/relay-git/install/setup.sh" | sudo tee $dir/init.sh > /dev/null
sudo git clone $hdir $dir/relay-git

mount_temp 0
mv $temp_img $final_img
