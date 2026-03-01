#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause
# Copy this script to same directory
# which contains SD card Raspberry Pi OS image file *.img and bootfs/*

MyWhich="$( which "$0" )"
MyPath="$( readlink -f "${MyWhich}" )"
MyDir="$( dirname "${MyPath}" )"
MyDirArg0="$( dirname "${MyWhich}" )"
MyBase="$( basename "$0" )"
MyBody="${MyBase%.*}"
MyBodyNoSuffix="${MyBody%%-*}"

CommonFile="${MyDir}/${MyBodyNoSuffix}-common.sh"

function LoadLayeredConfigFile() {
	local	name_next
	local	path
	local	path_a0
	local	path_rl
	local	path_a0_rl

	name_next="${1%-*}"
	if [[ "${name_next}" != "$1" ]]
	then
		LoadLayeredConfigFile "${name_next}"
	fi

	path="${MyDir}/$1.conf"
	if [[ -f "${path}" ]]
	then
		echo "$0: INFO: Load configuration file \"${path}\"."
		source "${path}"
	fi

	path_a0="${MyDirArg0}/$1.conf"
	if [[ -f "${path_a0}" ]]
	then
		path_rl="$( readlink -f "${path}" )"
		path_a0_rl="$( readlink -f "${path_a0}" )"
		if [[ "${path_rl}" != "${path_a0_rl}" ]]
		then
			echo "$0: INFO: Load configuration file \"${path_a0}\"."
			source "${path_a0}"
		fi
	fi
}

LoadLayeredConfigFile "${MyBase%.*}"

if [ -f "${CommonFile}" ]
then
	echo "$0: INFO: Load common file ${CommonFile}."
	source "${CommonFile}"
fi

[[ -z "${Append}" ]] && \
Append="console=ttyAMA1,115200 console=tty1\
 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait\
 dwc_otg.fiq_fsm_enable=0\
 bcm2708_fb.fbwidth=1024 bcm2708_fb.fbheight=768\
"

qemu-system-aarch64 \
-machine raspi3b \
-kernel "${KernelFile}" \
-initrd "${InitrdFile}" \
-dtb "${DtbFile}" \
-drive "${_DriveParam}" \
-append "${Append}" \
-serial mon:stdio \
-no-reboot \
-device usb-kbd \
-device usb-tablet \
-netdev "${NetDevOption}" \
-device "usb-net,netdev=net0,mac=${NicMac}" \
-display "${DisplayOutput}" \
"$@"
