#!/bin/bash
# Build BESI-C Rasbian Image and Write to SD Card
#   https://github.com/pennbauman/besic-device
#   Penn Bauman <pcb8gb@virginia.edu>
TEMP_FILE="$(mktemp)"
TEMP_IMG="/var/tmp/raspios_besic_temp.img"
TEMP_DIR="$(mktemp -d)"
IMG_DIR="$(pwd)/builds"
CACHE_DIR="$HOME/.cache/besic"

# Read secret image info
if [ -e ./secrets.conf ]; then
	source ./secrets.conf
fi

print_help() {
	echo "BESI-C Image Script"
	echo
	echo "  ./image.sh [type] <options...>"
	echo
	echo "Type: 'relay' or 'basestation', must be specified first"
	echo
	echo "Options:"
	echo "  --write, -w  Write image to SD card"
	echo "  --dev, -d    Create development image"
}

# Process command line parameters
TYPE="NONE"
WRITE="NO"
DEV="NO"
if (( $# > 0 )); then
	if [[ "$1" =~ ^-*h(elp|)$ ]]; then
		print_help
		exit 0
	fi

	# Get image type
	if [[ "$(echo $1 | tr a-z A-Z)" == "RELAY" ]]; then
		TYPE="RELAY"
	elif [[ "$(echo $1 | tr a-z A-Z)" == "BASESTATION" ]] || [[ "$(echo $1 | tr a-z A-Z)" == "BS" ]]; then
		TYPE="BASESTATION"
	elif [[ "$(echo $1 | tr a-z A-Z)" == "DEVBOX" ]]; then
		TYPE="DEVBOX"
	else
		if [[ "$1" =~ ^- ]]; then
			echo "Missing type"
		else
			echo "Unknown type '$1'"
		fi
		exit 1
	fi

	# Check for options
	if (( $# > 1 )); then
		for param in ${@:2}; do
			if [[ "$param" == "--write" ]] || [[ "$param" == "-w" ]]; then
				WRITE="YES"
			elif [[ "$param" == "--dev" ]] || [[ "$param" == "-d" ]]; then
				DEV="YES"
			elif [[ "$param" =~ ^- ]]; then
				echo "Unknown option '$param'"
				exit 1
			else
				echo "Invalid parameter '$param'"
				exit 1
			fi
		done
	fi
else
	print_help
	exit 0
fi



# Setup files for image
version_id="edited"
# If unchanged from commit use commit id
if [[ $(git status --short --untracked-files=no | wc -l) == 0 ]]; then
	version_id="$(git rev-parse HEAD)"
	version_id="${version_id:0:8}"
fi
# Identify development images
if [[ $DEV == "YES" ]]; then
	version_id="${version_id}_dev"
fi
FINAL_IMG="$IMG_DIR/raspios_besic_$(echo $TYPE | tr A-Z a-z)_$version_id.img"
# From https://www.raspberrypi.com/software/operating-systems
DESKTOP_URL="https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2022-04-07/2022-04-04-raspios-bullseye-armhf.img.xz"
LITE_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-04-07/2022-04-04-raspios-bullseye-armhf-lite.img.xz"
if [[ $TYPE == "RELAY" ]] || [[ $TYPE == "DEVBOX" ]]; then
	img_url="$LITE_URL"
	compressed_img="$CACHE_DIR/$(basename $LITE_URL)"
elif [[ $TYPE == "BASESTATION" ]]; then
	img_url="$DESKTOP_URL"
	compressed_img="$CACHE_DIR/$(basename $DESKTOP_URL)"
fi
BASE_IMG=${compressed_img:0: -3}

# Download image if necessary
if [ ! -f $BASE_IMG ]; then
	wget -q --show-progress $img_url -O $compressed_img
	xz -dv $compressed_img
	if [[ $? == 0 ]]; then
		rm -f $compressed_img
	else
		rm -f $BASE_IMG
		exit 1
	fi
	echo ""
	echo "> Base image downloaded ~${BASE_IMG#$HOME}"
else
	sudo sleep 0
	#echo "> Base image located ($(basename $BASE_IMG))"
	echo "> Base image located ~${BASE_IMG#$HOME}"
fi
touch $BASE_IMG


cp -u $BASE_IMG $TEMP_IMG



# Mount partition of image
mount_temp() {
	sudo umount $TEMP_IMG &> /dev/null
	# Create Mount Point
	mount="$TEMP_DIR/mnt$1"
	mkdir -p $mount
	# Find Partition Offsets
	data=$(fdisk -l $TEMP_IMG | grep $TEMP_IMG$1)
	if [[ $data == "" ]]; then
		echo "Partition '$1' not found"
		exit 1
	fi
	offset=$(echo $data | sed "s~$TEMP_IMG$1 *~~" | sed "s/ .*//")
	# Mount Partition
	if [[ $1 == 1 ]]; then
		sudo mount -o loop,offset=$((512*$offset)),umask=0000 $TEMP_IMG $mount
	elif [[ $1 == 2 ]]; then
		sudo mount -o loop,offset=$((512*$offset)) $TEMP_IMG $mount
	fi
}


# Edit boot partition
mount_temp 1
BOOT="$TEMP_DIR/mnt1"

# Enable SSH
echo "" > $BOOT/ssh
# Setup pi user with password
if [ -z ${PI_PSWD+x} ]; then
	read -p "Pi User Password: " PI_PSWD
fi
echo "pi:$(echo "$PI_PSWD" | openssl passwd -6 -stdin)" > $BOOT/userconf
# Add WiFi Network
echo "country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1" >> $BOOT/wpa_supplicant.conf
# Determine WiFi network
if [[ $TYPE == "RELAY" ]]; then
	WIFI_SSID="$BS_WIFI_SSID"
	WIFI_PSWD="$BS_WIFI_PSWD"
elif [[ $TYPE == "BASESTATION" ]] || [[ $TYPE == "DEVBOX" ]]; then
	WIFI_SSID="$SRC_WIFI_SSID"
	WIFI_PSWD="$SRC_WIFI_PSWD"
fi
# Get WiFi if not set
if [[ $WIFI_SSID == "" ]]; then
	read -p "SSID: " WIFI_SSID
fi
if [[ $WIFI_PSWD == "" ]]; then
	read -p "Password: " WIFI_PSWD
fi
# Write WiFi passphrase
wpa_passphrase "$WIFI_SSID" "$WIFI_PSWD" >> $BOOT/wpa_supplicant.conf
if [[ $? != 0 ]]; then
	echo "Wifi Setup Failed"
	sudo umount $TEMP_IMG
	exit 1
fi
sudo sed -i '/#/d' $BOOT/wpa_supplicant.conf
# Configure config.txt
if [[ $TYPE == "RELAY" ]]; then
	sudo sed -i 's/#dtparam=i2s=on/dtparam=i2s=on/' $BOOT/config.txt
	sudo sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' $BOOT/config.txt
elif [[ $TYPE == "BASESTATION" ]]; then
	sudo sed -i 's/#hdmi_mode=1/hdmi_mode=85/' $BOOT/config.txt
	sudo sed -i 's/#hdmi_group=1/hdmi_group=2/' $BOOT/config.txt
	sudo sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/' $BOOT/config.txt
fi

echo "> Boot partition setup"


# Edit main partition
mount_temp 2
ROOT="$TEMP_DIR/mnt2"

# Install setup script
sudo mkdir -m 777 -p $ROOT/var/besic/data $ROOT/var/log/besic
sudo mkdir -m 755 -p $ROOT/usr/share/besic $ROOT/etc/besic
sudo cp ./src/init.sh $ROOT/usr/share/besic/init.sh
sudo cp ./src/besic-init.service $ROOT/etc/systemd/system
sudo ln -s -r -T $ROOT/etc/systemd/system/besic-init.service $ROOT/etc/systemd/system/multi-user.target.wants/besic-init.service
# Setup S3 access
if [ ! -z ${S3_ACCESS_KEY+x} ] && [ ! -z ${S3_ACCESS_KEY+x} ]; then
	echo "S3_ACCESS_KEY=\"$S3_ACCESS_KEY\"
S3_SECRET_KEY=\"$S3_SECRET_KEY\"" | sudo tee $ROOT/var/besic/s3key.conf > /dev/null
fi

# Device specified configuration
if [[ $TYPE == "RELAY" ]]; then
	sudo cp ./src/relay.sh $ROOT/var/besic/setup.sh
	# Add snd-i2s_rpi source
	if [ ! -d $CACHE_DIR/snd-i2s-rpi ]; then
		git clone "https://github.com/besi-c/snd-i2s-rpi.git" $CACHE_DIR/snd-i2s-rpi
		git -C $CACHE_DIR/snd-i2s-rpi reset --hard e99ef23a12dbdce6b63b1ca5628630dd34bba426
	fi
	sudo cp -r $CACHE_DIR/snd-i2s-rpi/snd-i2s_rpi/src $ROOT/usr/src/snd-i2s_rpi-0.1.0
	# Enable kernel modules
	echo "i2c-dev" | sudo tee $ROOT/etc/modules-load.d/i2c-dev.conf > /dev/null
	echo "snd-i2smic-rpi" | sudo tee $ROOT/etc/modules-load.d/snd-i2smic-rpi.conf > /dev/null
elif [[ $TYPE == "BASESTATION" ]]; then
	sudo cp ./src/basestation.sh $ROOT/var/besic/setup.sh
	# Configure router
	sudo echo "ROUTER_SSID=\"$BS_WIFI_SSID\"
ROUTER_PSWD=\"$BS_WIFI_PSWD\"" | sudo tee $ROOT/etc/besic/router.conf > /dev/null
elif [[ $TYPE == "DEVBOX" ]]; then
	sudo cp ./src/devbox.sh $ROOT/var/besic/setup.sh
	# Configure router
	sudo echo "ROUTER_SSID=\"$DEV_WIFI_SSID\"
ROUTER_PSWD=\"$DEV_WIFI_PSWD\"" | sudo tee $ROOT/etc/besic/router.conf > /dev/null
fi
# Configure device type
sudo echo "# DO NOT EDIT
TYPE=\"$TYPE\"" | sudo tee $ROOT/etc/besic/type.conf > /dev/null

# Add APT repositories
if [[ $DEV == "YES" ]]; then
	echo "deb [trusted=yes] http://apt.besic.org/testing ./" | sudo tee -a $ROOT/etc/apt/sources.list.d/besic.list > /dev/null
	echo "libbesic2-dev vim git" | sudo tee $ROOT/var/besic/apt-get > /dev/null
	if [[ $TYPE == "BASESTATION" ]]; then
		echo "ranger" | sudo tee -a $ROOT/var/besic/apt-get > /dev/null
	fi
else
	echo "deb [trusted=yes] http://apt.besic.org/stable ./" | sudo tee -a $ROOT/etc/apt/sources.list.d/besic.list > /dev/null
fi

# Enable kernel modules
if [[ $TYPE == "RELAY" ]]; then
	echo "i2c-dev" | sudo tee $ROOT/etc/modules-load.d/i2c-dev.conf > /dev/null
	echo "snd-i2smic-rpi" | sudo tee $ROOT/etc/modules-load.d/snd-i2smic-rpi.conf > /dev/null
fi
echo "> Main partition setup"



# Finish build
sudo umount $TEMP_IMG
mkdir -p $IMG_DIR
mv $TEMP_IMG $FINAL_IMG
# Print final image location
wd=$(echo $(pwd) | sed 's/\//\\\//g')
final_file=$(echo $FINAL_IMG | sed "s/$wd/./")
echo "> Image build completed $final_file"

if [[ $WRITE == "YES" ]]; then
	if (( $(lsblk -ln | grep disk | grep ^mmc | wc -l) == 1 )); then
		disk=$(lsblk -ln | grep disk | grep ^mmc | sed 's/ .*//')
		echo "> Writing image to /dev/$disk"
		sudo dd if="$FINAL_IMG" of="/dev/$disk" bs=4M status=progress conv=fsync
	else
		echo "SD Card for install not found"
	fi
fi
