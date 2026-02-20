#!/bin/bash

imager="downloads/host/rpi3image.sh"
	link_from="rpi2image.sh"
	if [[ ( ! -h "${link_from}" ) && ( ! -f "${link_from}" ) ]]
	then
		ln -s "${imager}" "${link_from}"
	fi

for f in "downloads/host/rpi2vm32.conf" \
	 "downloads/host/rpi2vm32-common.sh" \
	 "downloads/host/rpi2vm32.sh" \
	 "downloads/host/rpi2vm32-upkernel.sh"
do
	if [[ ! -f "${f}" ]]
	then
		echo "$0: ERROR: Can not find \"${f}\"."
		exit 1
	fi
	link_from="${f##*/}"
	if [[ ( ! -h "${link_from}" ) && ( ! -f "${link_from}" ) ]]
	then
		ln -s "${f}" "${link_from}"
	fi
done

link_to="downloads/host/rpi2vm32.sh"
for link_from in "rpi2vm32-1st.sh" "rpi2vm32-2nd.sh"
do
	if [[ ( ! -h "${link_from}" ) && ( ! -f "${link_from}" )  ]]
	then
		ln -s "${link_to}" "${link_from}"
	fi
done

echo "$0: HELP: Imager:      ./rpi2image.sh"
echo "$0: HELP: 1st-setup:   ./rpi2vm32-1st.sh"
echo "$0: HELP:                Launch configuration process."
echo "$0: HELP:                Terminate QEMU [CTRL]-[a] [x] after reboot failed."
echo "$0: HELP: 2nd-setup:   ./rpi2vm32-2nd.sh"
echo "$0: HELP:                Login and run \"sudo /var/local/post-setup.sh; \\"
echo "$0: HELP:                sudo /sbin/init 0\"."
echo "$0: HELP: normal-boot: ./rpi2vm32.sh"
echo "$0: HELP:                Normal operation."
echo "$0: HELP: copy-kernel: ./rpi2vm32-upkernel.sh"
echo "$0: HELP:                Copy kernel and initrd files from SDCard/eMMC image file to bootfs/."
