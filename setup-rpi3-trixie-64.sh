#!/bin/bash

for f in "downloads/host/rpi3image.sh" \
	 "downloads/host/rpi3vm64.conf" \
	 "downloads/host/rpi3vm64-common.sh" \
	 "downloads/host/rpi3vm64.sh" \
	 "downloads/host/rpi3vm64-upkernel.sh"
do
	if [[ ! -f "${f}" ]]
	then
		echo "$0: ERROR: Can not find \"${f}\"."
		exit 1
	fi
	link_from="${f##*/}"
	if [[ ( ! -h "${link_from}" ) || ( ! -f "${link_from}" ) ]]
	then
		ln -s "${f}" "${link_from}"
	fi
done

link_to="downloads/host/rpi3vm64.sh"
for link_from in "rpi3vm64-1st.sh" "rpi3vm64-2nd.sh"
do
	if [[ ( ! -h "${link_from}" ) || ( ! -f "${link_from}" )  ]]
	then
		ln -s "${link_to}" "${link_from}"
	fi
done

echo "$0: HELP: Imager:      ./rpi3image.sh"
echo "$0: HELP: 1st-setup:   ./rpi3vm64-1st.sh"
echo "$0: HELP:                Launch configuration process."
echo "$0: HELP:                Terminate QEMU [CTRL]-[a] [x] after reboot failed."
echo "$0: HELP: 2nd-setup:   ./rpi3vm64-2nd.sh"
echo "$0: HELP:                Login and run \"sudo /var/local/post-setup.sh; \\"
echo "$0: HELP:                sudo /sbin/init 0\"."
echo "$0: HELP: normal-boot: ./rpi3vm64.sh"
echo "$0: HELP:                Normal operation."
echo "$0: HELP: copy-kernel: ./rpi3vm64-upkernel.sh"
echo "$0: HELP:                Copy kernel and initrd files from SDCard/eMMC image file to bootfs/."
