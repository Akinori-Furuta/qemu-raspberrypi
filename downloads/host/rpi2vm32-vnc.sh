#!/bin/bash
# Copy this script to same directory
# which contains SD card Raspberry Pi OS image file *.img and bootfs/*

MyWhich="$( which "$0" )"
MyPath="$( readlink -f "${MyWhich}" )"
MyDir="$( dirname "${MyPath}" )"
MyBase="$( basename "$0" )"
MyBody="${MyBase%.*}"
MyBodyNoSuffix="${MyBody%%-*}"

ConfigFile="${MyDir}/${MyBody}.conf"
CommonFile="${MyDir}/${MyBodyNoSuffix}-common.sh"

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

qemu-system-arm \
-machine raspi2b \
-kernel "${KernelFile}" \
-initrd "${InitrdFile}" \
-dtb "${DtbFile}" \
-drive "format=raw,file=${SdFile}" \
-append "console=ttyAMA0,115200 console=tty1\
 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait\
 dwc_otg.fiq_fsm_enable=0\
 bcm2708_fb.fbwidth=1024 bcm2708_fb.fbheight=768\
" \
-serial mon:stdio \
-no-reboot \
-device usb-kbd \
-device usb-tablet \
-netdev "tap,br=${NicBridge},helper=/usr/lib/qemu/qemu-bridge-helper-suid,id=net0" \
-device "usb-net,netdev=net0,mac=${NicMac}" \
-vnc "${VncDisplay}" \
"$@"
