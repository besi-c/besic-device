# BESI-C Relay


## Raspberry Pi Image
Download Raspberry Pi OS Lite and build custom image:

	./image/build.sh

Write image to SD card:

	sudo dd if=./image/besic_relay_raspios.img of=/dev/SD_CARD bs=4M status=progress conv=fsync
