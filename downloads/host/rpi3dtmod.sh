#!/bin/bash

CurDir="$(pwd)"

DTC="dtc"
BootFs="bootfs"
Raspi3BDtb="bcm2710-rpi-3-b.dtb"
Raspi3BDts="${Raspi3BDtb%.dtb}.dts"
Raspi3BQemuDtb="bcm2710-rpi-3-b-qemu.dtb"
Raspi3BQemuDts="${Raspi3BQemuDtb%.dtb}.dts"

function ExitProc() {
	cd "${CurDir}"
}

if ! which "${DTC}" > /dev/null
then
	echo "$0: Install Device Tree Compiler (dtc)."
	echo "$0: sudo apt install device-tree-compiler"
	ExitProc
	exit 1
fi

if [ ! -d "${BootFs}" ]
then
	echo "$0: Can not find ${BootFs} directory, which contains files"
	echo "$0: copied from Raspberry Pi OS bootfs partition."
	ExitProc
	exit 1
fi

cd "${BootFs}"

if [ ! -f "${Raspi3BDtb}" ]
then
	echo "$0: Can not find ${BootFs}/${Raspi3BDtb}"
	ExitProc
	exit 1
fi

if ! file "${Raspi3BDtb}" | grep -q -i 'Device[[:space:]]*Tree'
then
	echo "$0: Not device tree file ${BootFs}/${Raspi3BDtb}"
	ExitProc
	exit 1
fi

if ! dtc -I dtb -O dts "${Raspi3BDtb}" > "${Raspi3BDts}"
then
	ExitProc
	exit 2
fi

if ! cp -p "${Raspi3BDts}" "${Raspi3BQemuDts}"
then
	ExitProc
	exit 2
fi

patch -i - "${Raspi3BQemuDts}" << EOF_PATCH
--- bcm2710-rpi-3-b.dts	2025-03-09 02:52:01.396025199 +0900
+++ bcm2710-rpi-3-b-qemu.dts	2025-03-09 02:54:36.330747015 +0900
@@ -567,7 +567,7 @@
 				shutdown-gpios = <0x0b 0x00 0x00>;
 				local-bd-address = [00 00 00 00 00 00];
 				fallback-bd-address;
-				status = "okay";
+				status = "disabled";
 				phandle = <0x3a>;
 			};
 		};
EOF_PATCH
if $? != 0
then
	exit $?
fi

if ! dtc -I dts -O dtb "${Raspi3BQemuDts}" > "${Raspi3BQemuDtb}"
then
	ExitProc
	exit 2
fi

echo "$0: Converted ${BootFs}/${Raspi3BDtb} into ${BootFs}/${Raspi3BQemuDtb}"

ExitProc
exit 0
