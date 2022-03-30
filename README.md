# BESI-C Relay
Scripts to build Raspberry Pi OS image for various BESI-C devices

## Usage
To build a relay image run:

	./image.sh relay

To build a basestation image run:

	./image.sh basestation

or `./image.sh bs`

### Options
Options must be placed after the device type, ie:

	./image.sh relay --dev --write

| Options | Short | Descriptions |
|--------:|------:|:---|
|  `--dev`|   `-d`| Creates a development image, using testing package repo |
|`--write`|   `-w`| Write image to inserted SD card |
