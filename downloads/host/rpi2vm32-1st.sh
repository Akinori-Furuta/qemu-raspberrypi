#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause
# Copy this script to same directory
# which contains SD card Raspberry Pi OS image file *.img and bootfs/*

MyWhich="$( which "$0" )"
MyPath="$( readlink -f "${MyWhich}" )"
MyDir="$( dirname "${MyPath}" )"
MyBase="$( basename "$0" )"
MyBody="${MyBase%.*}"
MyBodyNoSuffix="${MyBody%%-*}"

ConfigFile="${MyDir}/${MyBody%-*}.conf"
CommonFile="${MyDir}/${MyBodyNoSuffix}-common.sh"

if [ -f "${ConfigFile}" ]
then
	echo "$0: INFO: Load configuration file ${ConfigFile}."
	source "${ConfigFile}"
fi

if [ -f "${CommonFile}" ]
then
	echo "$0: INFO: Load common file ${CommonFile}."
	source "${CommonFile}"
fi

qemu-system-arm \
-machine raspi2b \
-kernel "${KernelFile}" \
-initrd "${InitrdFile}" \
-dtb "${DtbFile}" \
-drive "${_DriveParam}" \
-append "console=ttyAMA0,115200 console=tty1\
 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait\
 dwc_otg.fiq_fsm_enable=0\
 bcm2708_fb.fbwidth=1024 bcm2708_fb.fbheight=768\
 init=/usr/lib/raspberrypi-sys-mods/firstboot\
 systemd.run=/boot/firstrun.sh\
 systemd.run_success_action=reboot\
 systemd.unit=kernel-command-line.target\
" \
-serial mon:stdio \
-no-reboot \
-device usb-kbd \
-device usb-tablet \
-display "${DisplayOutput}" \
"$@"

first_run="${MyDir}/bootfs/firstrun.sh"
if [ -f "${first_run}" ]
then
	# No other can read firstrun.sh, which contains hashed password
	# and WiFi pass phrase.
	chmod 600 "${first_run}"
	echo "$0: If you want more secure, rm ${first_run}."
fi
