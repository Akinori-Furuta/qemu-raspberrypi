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

if [ -f "${ConfigFile}" ]
then
	echo "$0: INFO: Load configuration file ${ConfigFile}."
	source "${ConfigFile}"
fi

if [ -f "${CommonFile}" ]
then
	if [ -z "${VncDisplay}" ]
	then
		# Not configured VNC display.
		# Set temporal VncDisplay value.
		VncDisplay="unix:/"
	fi
	echo "$0: INFO: Load common file ${CommonFile}."
	source "${CommonFile}"
fi

if [[ -z "${VncDisplay}" ]]
then
	# Accept connection from any host.
	# Search available port.
	_VncNumber=$( RaspiVncNumber )
	echo "$0: INFO: VNC URI is vnc://$(hostname).local:${_VncNumber}"
else
	if [[ "${VncDisplay}" == unix:/ ]]
	then
		# Accept VNC connection on UNIX domain socket.
		# Place socket beside this script.
		VncDisplay="unix:/${MyDir}/${MyBody}.sock"
		echo "$0: INFO: VNC URI is \"vnc+unix://${MyDir}/${MyBody}.sock\""
		echo "$0: INFO: Some apps can't recognize above URI, you may arrange it."
	else
		if [[ "${VncDisplay}" == unix:/* ]]
		then
			# Accept VNC connection on UNIX domain socket.
			# Configured path to socket.
			echo "$0: INFO: VNC URI is \"vnc+${VncDisplay}\""
			echo "$0: INFO: Some apps can't recognize above URI, you may arrange it."
		else
			# Accept VNC on network port.
			if  [[ "${VncDisplay}" == *:\*   ]]
			then
				# Specified host and Search available port.
				_VncNumber=$( RaspiVncNumber )
				VncDisplay="${VncDisplay%:*}:${_VncNumber}"
			fi
			vnc_address="${VncDisplay%:*}"
			if [ -n "${vnc_address}" ]
			then
				echo "$0: INFO: VNC URI is vnc://${vnc_address}:${VncDisplay##*:}"
				echo "$0: INFO: Accept VNC connection on ${vnc_address}"
			else
				echo "$0: INFO: VNC URI is vnc://$(hostname).local:${VncDisplay##*:}"
			fi
		fi
	fi
fi

[[ -z "${Append}" ]] && \
Append="console=ttyAMA1,115200 console=tty1\
 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait\
 dwc_otg.fiq_fsm_enable=0\
 bcm2708_fb.fbwidth=1024 bcm2708_fb.fbheight=768\
"

echo "$0: INFO: Append=${Append}"

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
-vnc "${VncDisplay}" \
"$@"
