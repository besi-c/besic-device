#!/bin/bash
# BESI-C Relay Init Runner
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>
# location in image: /etc/rc.local


INIT_SH="/var/besic/init.sh"

if [ -f $INIT_SH ]; then
	chmod +x $INIT_SH
	bash $INIT_SH
fi

exit 0
