#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause

PATH=/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin

MyWhich="$( which "$0" )"
MyPath="$( readlink -f "${MyWhich}" )"
MyDir="$( dirname "${MyPath}" )"
MyDirArg0="$( dirname "$0" )"
MyDirArg0Absolute="$( readlink -f "${MyDirArg0}" )"
MyBase="$( basename "$0" )"
MyBody="${MyBase%.*}"
MyBodyNoSuffix="${MyBody%%-*}"

for f in "downloads/host/rpi3vm64-1st.conf.bookworm" \
	 "downloads/host/rpi3vm64-2nd.conf.bookworm"
do
	if [[ ( ! -h "${f}" ) && ( ! -f "${f}" ) ]]
	then
		echo "$0: ERROR: Can not find \"${f}\"." 1>&2
		exit 1
	fi

	link_from="${f%.*}"
	link_to="${f##*/}"
	if [[ ( ! -h "${link_from}" ) && ( ! -f "${link_from}" ) ]]
	then
		if ! ln -s "${link_to}" "${link_from}"
		then
			echo "$0: ERROR: Can not create symbolic-links. from=\"${link_from}\", to=\"${link_to}\"" 1>&2
			exit 1
		fi
	fi
done

for f in "downloads/host/rpi3image.sh" \
	 "downloads/host/rpi3vm64-1st.conf" \
	 "downloads/host/rpi3vm64-2nd.conf" \
	 "downloads/host/rpi3vm64.conf" \
	 "downloads/host/rpi3vm64-common.sh" \
	 "downloads/host/rpi3vm64.sh" \
	 "downloads/host/rpi3vm64-upkernel.sh"
do
	if [[ ( ! -f "${f}" ) && ( ! -h "${f}" ) ]]
	then
		echo "$0: ERROR: Can not find \"${f}\"."
		exit 1
	fi
	link_from="${f##*/}"
	if [[ ( ! -h "${link_from}" ) && ( ! -f "${link_from}" ) ]]
	then
		if ! ln -s "${f}" "${link_from}"
		then
			echo "$0: ERROR: Can not create symbolic-links. from=\"${link_from}\", to=\"${f}\"" 1>&2
			exit 1
		fi
	fi
done

link_to="downloads/host/rpi3vm64.sh"
for link_from in "rpi3vm64-1st.sh" "rpi3vm64-2nd.sh"
do
	if [[ ( ! -h "${link_from}" ) && ( ! -f "${link_from}" )  ]]
	then
		if ! ln -s "${link_to}" "${link_from}"
		then
			echo "$0: ERROR: Can not create stater symbolic-links. from=\"${link_from}\", to=\"${link_to}\"" 1>&2
			exit 1
		fi
	fi
done

echo "$0: HELP: Imager:      ./rpi3image.sh"
echo "$0: HELP: 1st-setup:   ./rpi3vm64-1st.sh"
echo "$0: HELP:                Launch 1st configuration process."
echo "$0: HELP:                Wait until terminate."
echo "$0: HELP: 2nd-setup:   ./rpi3vm64-2nd.sh"
echo "$0: HELP:                Launch 2nd configuration process."
echo "$0: HELP:                Wait until terminate."
echo "$0: HELP: normal-boot: ./rpi3vm64.sh"
echo "$0: HELP:                Normal operation."
echo "$0: HELP:                Click GUI dialog [Keep X] button."
echo "$0: HELP: copy-kernel: ./rpi3vm64-upkernel.sh"
echo "$0: HELP:                Copy kernel and initrd files from"
echo "$0: HELP:                SDCard/eMMC image file to bootfs/."
