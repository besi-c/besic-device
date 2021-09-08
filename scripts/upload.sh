#!/bin/bash
# BESI-C Relay Data Upload
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>

DIR="/var/besic"
DATA_DIR="$DIR/data"
LOG="/var/log/besic/upload.log"

# Create zip file
name="$(/usr/bin/uuid)"
zip $DATA_DIR/$name.zip $DATA_DIR/*.csv
rm -f $DATA_DIR/*.csv

# Check zip files exists
if (( $(find $DATA_DIR -name "*.zip" | wc -l) == 0 )); then
	echo "[$(date --rfc-3339=seconds)]: No data to uploaded" >> $LOG
	exit
fi

# Get configuration
source $DIR/deploy.conf
source $DIR/secrets.conf

# Upload zip files
for f in $DATA_DIR/*.zip; do
	python3 $DIR/s3-uploader.py $f
	if (( $? != 0 )); then
		rm $f
		echo "[$(date --rfc-3339=seconds)]: $(basename $f) uploaded" >> $LOG
	else
		echo "[$(date --rfc-3339=seconds)]: $(basename $f) upload failed" >> $LOG
	fi
done
