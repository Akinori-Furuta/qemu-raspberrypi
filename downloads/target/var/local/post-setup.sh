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

if (( ${RaspiOsReleaseNo} < ${RaspiOsReleaseTrixie} ))
then
	sudo systemctl disable hciuart.service
else
	echo "$0: INFO: Skip disable hciuart.service."
fi

sudo systemctl disable ModemManager.service
sudo systemctl disable rpi-eeprom-update.service
