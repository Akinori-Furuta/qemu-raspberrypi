#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RaspiOsReleaseBookworm=12
RaspiOsReleaseTrixie=13

RaspiOsReleaseNo=$( grep 'VERSION_ID' "/etc/os-release" \
	| awk 'BEGIN {FS="="} {print $2}' \
	| tr -d '"' )

KernelArch="$(uname -m)"

# Remove first run script, it contains password and pass phrase.
rm -f /boot/firmware/firstrun.sh
# Lock user rpi-first-boot-wizard
sudo usermod -L rpi-first-boot-wizard

# Switch Window system to X Window System

LightdmConf=/etc/lightdm/lightdm.conf
window_system=""

if grep -q -i '=.*-labwc' "${LightdmConf}"
then
	window_system="labwc"
else
	if grep -q -i '=.*-x' "${LightdmConf}"
	then
		window_system="x"
	fi
fi

if [[ "${window_system}" != x ]]
then
	echo "$0: INFO: Configure 6/A6/W1 X11: Openbox window manager with X11 backend."
	/usr/bin/sudo /usr/bin/raspi-config nonint do_wayland W1
fi

# Disable services, they don't work well on emulator.

linux_headers_pkg=""

if (( ${RaspiOsReleaseNo} < ${RaspiOsReleaseTrixie} ))
then
	echo "$0: INFO: Disable hciuart."
	sudo systemctl disable hciuart.service
	linux_headers_pkg="linux-headers"
else
	echo "$0: INFO: Skip disable hciuart.service."
	case "${KernelArch}" in
	(armv6l)
		linux_headers_pkg="linux-headers-rpi-v6"
		;;
	(armv7l)
		linux_headers_pkg="linux-headers-rpi-v7"
		;;
	(aarch64|armv8l)
		linux_headers_pkg="linux-headers-rpi-v8"
		;;
	(*)
		linux_headers_pkg="linux-headers"
		;;
	esac
fi

echo "$0: INFO: Disable ModemManager."
sudo systemctl disable ModemManager.service

echo "$0: INFO: Disable rpi-eeprom-update."
sudo systemctl disable rpi-eeprom-update.service

BCM2835PowerOffDkms="/usr/src/bcm2835-power-off-dkms-1.0"
BCM2835PowerOffDkmsModule="bcm2835-power-off-dkms/1.0"
BCM2835PowerOff="bcm2835_power_off"
ModuleBaseDir="/lib/modules"

function KernelSymbolCrc() {
	grep -w "$2" "$1" | awk '{print $1}'
}

function ModuleSymbolCrc() {
	modprobe --show-modversions "$1" | grep -w "${2}" | awk '{print $1}'
}

if [[ -d "${BCM2835PowerOffDkms}" ]]
then
	echo "$0: INFO: Install dkms, ${linux_headers_pkg}, build-essential, and kmod packages."

	retries=0
	while ! sudo apt install -y dkms "${linux_headers_pkg}" build-essential kmod
	do
		retries=$(( ${retries} + 1 ))
		if (( ${retries} <= 3 ))
		then
			echo "$0: NOTICE: Retry install. retries=${retries}"
		else
			echo "$0: ERROR: Can not install package(s)."
			exit 1
		fi
	done

	kernel_version="$(uname -r)"
	arch="$(uname -m)"

	( cd "${ModuleBaseDir}" ; ls ) | while read
	do
		if [[ ! -d "${ModuleBaseDir}/${REPLY}" ]]
		then
			continue
		fi

		build_link="${ModuleBaseDir}/${REPLY}/build"
		if [[ ! -e "${build_link}" ]]
		then
			echo "$0: NOTICE: No headers to build a dkms driver. kernel_version=\"${REPLY}\"."
			continue
		fi

		dkms_ready="yes"

		kernel_arch="${REPLY}/${arch}"

		BCM2835PowerOffKo="${ModuleBaseDir}/${REPLY}/updates/dkms/${BCM2835PowerOff}.ko"
		if [[ ! -f "${BCM2835PowerOffKo}" ]]
		then
			for comp in .xz .gz .zst
			do
				ko_comp="${BCM2835PowerOffKo}${comp}"
				if [[ -f "${ko_comp}" ]]
				then
					BCM2835PowerOffKo="${ko_comp}"
					break
				fi
			done
		fi

		if [[ -f "${BCM2835PowerOffKo}" ]]
		then
			# Kernel module .ko exist.

			symvers_file="${ModuleBaseDir}/${REPLY}/build/Module.symvers"
			kcrc_dev_info="0xffffffff"
			kcrc_of_find_property="0xffffffff"
			if [[ -f "${symvers_file}" ]]
			then
				kcrc_dev_info="$( KernelSymbolCrc "${symvers_file}" "_dev_info" )"
				kcrc_of_find_property="$( KernelSymbolCrc "${symvers_file}" "of_find_property" )"
			fi

			modcrc_dev_info="$( ModuleSymbolCrc "${BCM2835PowerOffKo}" "_dev_info" )"
			modcrc_of_find_property="$( ModuleSymbolCrc "${BCM2835PowerOffKo}" "of_find_property" )"
			if [[ ( "${kcrc_dev_info}" != "${modcrc_dev_info}" ) ||
			      ( "${kcrc_of_find_property}" != "${modcrc_of_find_property}" )
			]]
			then
				# Symbol CRC value(s) is(are) not match.
				# So called, "disagrees about version of symbol" or
				# "Invalid argument" at modprobe.
				# Remove .ko, and will rebuild it.
				echo "$0: INFO: Remove dkms driver \"${BCM2835PowerOffDkms}\" from ${kernel_arch}."
				sudo dkms remove "${BCM2835PowerOffDkmsModule}" -k "${kernel_arch}"
			fi
		fi

		if [[ ! -f "${BCM2835PowerOffKo}" ]]
		then
			echo "$0: INFO: Install dkms driver \"${BCM2835PowerOffDkms}\" to ${kernel_arch}."
			sudo dkms build "${BCM2835PowerOffDkmsModule}" -k "${kernel_arch}" || dkms_ready=""
			sudo dkms install "${BCM2835PowerOffDkmsModule}" -k "${kernel_arch}" || dkms_ready=""
			sync
		else
			echo "$0: NOTICE: Already installed dkms driver \"${BCM2835PowerOffDkms}\" to ${kernel_arch}."
		fi

		if [[ ( -n "${dkms_ready}" ) && ( "${REPLY}" == "${kernel_version}" ) ]]
		then
			echo "$0: INFO: Install module \"${BCM2835PowerOff}\" into kernel."
			sudo modprobe "${BCM2835PowerOff}"
		fi
	done
fi
