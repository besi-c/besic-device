#!/bin/bash
# BESI-C Relay Init Runner
#   https://github.com/pennbauman/besic-relay
#   Penn Bauman <pcb8gb@virginia.edu>
# location in image: /etc/rc.local


init_sh="/var/besic/init.sh"

if [ -f $init_sh ]; then
	chmod +x $init_sh
	bash $init_sh
fi

exit 0
