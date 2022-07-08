# BESI-C Device Images
Scripts to build Raspberry Pi OS images for BESI-C devices



## Usage
To get basic usage info run:

	./image.sh --help

To build a relay image run:

	./image.sh relay

To build a basestation image run:

	./image.sh basestation

or `./image.sh bs`

To build a package development image run:

	./image.sh devbox


### Command Line Options
Options must be placed after the device type (ie `./image.sh relay --dev --write`)

| Options | Short | Descriptions |
|--------:|------:|:---|
|  `--dev`|   `-d`| Creates a development image, using testing package repo |
|`--write`|   `-w`| Write image to inserted SD card |


### Using `secrets.conf`
The build script uses a variety of info which cannot be save in this repository for security reasons. This data can be saved in the `secrets.conf` file to simplify local development, or entered manually as the script runs. A sample copy of `secrets.conf` is available with blank variables and can be used by running `cp -n sample-secrets.conf secrets.conf`.


The password for a device will be asked for if not in `secrets.conf` and can be set with:

	PI_PSWD="********"

Keys to connect to AWS will **not** be asked for or install if not in `secrets.conf` and can be set with:

	S3_ACCESS_KEY="********"
	S3_SECRET_KEY="********"

WiFi networks are the most complex element of `secrets.conf` as different types of devices connect to different networks. If the appropriate variable is not set in `secrets.conf` the build script will ask for a WiFi network SSID and password, which will be the network the device attempts to connect to. If a device functions as a router the appropriate variable must be set in `secrets.conf` to  configure router functionality.

The WiFi network relay devices connect to and basestation devices provide can be set with:

	BS_WIFI_SSID="WiFi Name"
	BS_WIFI_PSWD="*********"

The WiFi network basestation devices connect to and devbox devices provide can be set with:

	HOTSPOT_SSID="WiFi Name"
	HOTSPOT_PSWD="********"

The WiFi network devbox device connect to is set with:

	DEV_WIFI_SSID="WiFi Name"
	DEV_WIFI_PSWD="********"



## Image Version
Built images include an version identifier consisting of the first 8 character of the current git commit hash if they are built with a clean git repository. If the repository has be edited, this version identified will instead by `edited`.

For example a relay image create with git commit `ac27a796d28782240d3f37ecd87ee1e850c13dc8` will have the filename `raspios_besic_relay_ac27a796.img`. While another relay image built after `image.sh` is changed will have the filename `raspios_besic_relay_edited.img`.



## Development Images
Images created with the `--dev` option use the testing package repository and can be identified by `_dev` at the end of their filename (ie `raspios_besic_relay_ac27a796_dev.img`). These images will also have a few extra programs installed on them by default. Devices can be switched between using stable and development packages by changing the `/etc/apt/sources.list.d/besic.list` file. This file on development images contains:

	deb [trusted=yes] http://apt.besic.org/testing ./

While on stable images it contains:

	deb [trusted=yes] http://apt.besic.org/stable ./
