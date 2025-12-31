#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RaspiOsReleaseBookworm=12
RaspiOsReleaseTrixie=13

RaspiOsReleaseNo=$( grep 'VERSION_ID' "/etc/os-release" \
	| awk 'BEGIN {FS="="} {print $2}' \
	| tr -d '"' )

# Remove first run script, it contains password and pass phrase.
rm -f /boot/firmware/firstrun.sh
# Lock user rpi-first-boot-wizard
sudo usermod -L rpi-first-boot-wizard

# Disable services, they don't work well on emulator.

linux_headers_pkg=""

if (( ${RaspiOsReleaseNo} < ${RaspiOsReleaseTrixie} ))
then
	echo "$0: INFO: Disable hciuart."
	sudo systemctl disable hciuart.service
	linux_headers_pkg="linux-headers"
else
	echo "$0: INFO: Skip disable hciuart.service."
	linux_headers_pkg="linux-headers-rpi-v8"
fi

BCM2835PowerOffDkms="/usr/src/bcm2835-power-off-dkms-1.0"
BCM2835PowerOff="bcm2835_power_off"
BCM2835PowerOffKo="/lib/modules/$(uname -r)/updates/dkms/${BCM2835PowerOff}.ko.xz"

if [[ -d "${BCM2835PowerOffDkms}" ]]
then
	echo "$0: INFO: Install dkms, ${linux_headers_pkg}, build-essential, and kmod packages."
	sudo apt install -y dkms "${linux_headers_pkg}" build-essential kmod
	dkms_ready="yes"
	if [[ ! -f "${BCM2835PowerOffKo}" ]]
	then
		echo "$0: INFO: Install dkms driver \"${BCM2835PowerOffDkms}\"."
		sudo dkms build bcm2835-power-off-dkms/1.0 || dkms_ready=""
		sudo dkms install bcm2835-power-off-dkms/1.0 || dkms_ready=""
	else
		echo "$0: NOTICE: Skip installing dkms driver \"${BCM2835PowerOffDkms}\"."
	fi

	if [[ -n "${dkms_ready}" ]]
	then
		echo "$0: INFO: Install module \"${BCM2835PowerOff}\" into kernel."
		sudo modprobe "${BCM2835PowerOff}"
	fi
fi

echo "$0: INFO: Disable ModemManager."
sudo systemctl disable ModemManager.service

echo "$0: INFO: Disable rpi-eeprom-update."
sudo systemctl disable rpi-eeprom-update.service
