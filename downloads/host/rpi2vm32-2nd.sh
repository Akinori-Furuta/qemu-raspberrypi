#!/bin/bash
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

echo "$0: INFO: VNC URI is vnc://localhost:${VncNumber}"

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
 systemd.run=/boot/firmware/firstrun.sh\
 systemd.run_success_action=reboot\
 systemd.unit=kernel-command-line.target\
" \
-serial mon:stdio \
-no-reboot \
-device usb-kbd \
-device usb-tablet \
-vnc "localhost:${VncNumber}" \
"$@"
