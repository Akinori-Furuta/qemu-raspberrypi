#!/bin/bash
# Copy this script to same directory
# which contains SD card Raspberry Pi OS image file *.img and bootfs/*
# Source this file from rpi3vm64-1st.sh, rpi3vm64-2nd.sh or rpi3vm64.sh

MyTemp=""

# At exit procedure
function ExitProc() {
	if [ -n "${MyTemp}" ] && [ -d "${MyTemp}" ]
	then
		rm -rf "${MyTemp}"
	fi
}

trap ExitProc EXIT

# Find Temporary Directory.
function TempDirectoryFind() {
	local Temp

	for Temp in /run/user/$(id -u) /dev/shm /ramdisk "${TMP}" "${TEMP}" /tmp
	do
		if [ -z "${Temp}" ]
		then
			continue
		fi
		if [ -d "${Temp}" ] && \
		   [ -r "${Temp}" ] && [ -w "${Temp}" ] && [ -x "${Temp}" ]
		then
			break
		fi
	done
	echo "${Temp}"
}

# Generate random value.
function HashedRamdom() {
	( cat /proc/sys/kernel/random/uuid; date +%s.%N ) | sha256sum | cut -f 1 -d ' '
}

MyTemp="$( TempDirectoryFind )/${MyBody}-$$-$( HashedRamdom )"
MyTempReady=

# Prepare Temporal directory.
function TempDirectoryPrepare() {
	if [ -n "${MyTempReady}" ]
	then
		return 0
	fi
	while ! mkdir "${MyTemp}"
	do
		MyTemp="$( TempDirectoryFind )/${MyBody}-$$-$( HashedRamdom )"
	done

	chmod 700 "${MyTemp}"
	[ -n "${debug}" ] && echo "$0.TempDirectoryPrepare: DEBUG: Create temporal directory. MyTemp=\"${MyTemp}\"" 1>&2
	MyTempReady=yes
	return 0
}

# Detect File Type
function QemuImgType() {
	[ -n "${debug}" ] && echo "$0.QemuImgType: DEBUG: Detect image file type. file=\"$1\"" 1>&2
	qemu-img info "$1"  | grep -i 'file[[:space:]]\+format' | sed  's/^.*:[[:space:]]*//'
}

# Find Raspberry Pi OS SD card image file
# Assume image file contains following blocks,
#  DOS/MBR partition
#  partition 1 (bootfs)
#  partition 2 (rootfs)
function RaspiImgFind() {
	[ -n "${debug}" ] && echo "$0.RaspiImgFind: DEBUG: RaspiImgFind() enter." 1>&2
	(ls *.img *.qcow *.qcow2 2>/dev/null ) | grep -v -i '^swap' | sort | \
	(	sub_result=1
		sd_file_list=()
		sd_file_index=0

		while read
		do
			[ -n "${debug}" ] && echo "$0.RaspiImgFind: DEBUG: Check file. REPLY=\"${REPLY}\"" 1>&2
			if [ -w "${REPLY}" ]
			then
				if file -L "${REPLY}" | \
				   grep -q 'DOS/MBR.*1 : ID=0xc.*2 : ID=0x83'
				then
					sd_file_list[${sd_file_index}]="${REPLY}"
					sd_file_index=$(( ${sd_file_index} + 1 ))
				else
					if file -L "${REPLY}" | \
					   grep -q -i 'QCOW'
					then
						TempDirectoryPrepare
						TempFileBody="$( basename "${REPLY}" | tr -d '[:space:]' )"
						TempFileBody="${TempFileBody%.*}-$( HashedRamdom ).img"
						TempImg="${MyTemp}/${TempFileBody}"
						touch "${TempImg}"
						chmod 600 "${TempImg}"
						qcow_type=$( QemuImgType "${REPLY}" )
						qemu-img dd -f ${qcow_type} -O raw bs=512 count=4096 \
						        "if=${REPLY}" "of=${TempImg}"

						if file "${TempImg}" | \
						   grep -q 'DOS/MBR.*1 : ID=0xc.*2 : ID=0x83'
						then
							sd_file_list[${sd_file_index}]="${REPLY}"
							sd_file_index=$(( ${sd_file_index} + 1 ))
						fi
						rm "${TempImg}"
					fi
				fi
			else
				echo "$0: INFO: Skip read only file \"${REPLY}\"" 1>&2
			fi
		done

		if (( ${sd_file_index} > 1 ))
		then
			echo "$0: NOTICE: There are ${sd_file_index} Raspberry Pi OS SD card image files as follows," 1>&2
			echo -n "$0: NOTICE: " 1>&2
			sd_file_i=0
			while (( ${sd_file_i} < ${sd_file_index} ))
			do
				echo -n " \"${sd_file_list[${sd_file_i}]}\"" 1>&2
				sd_file_i=$(( ${sd_file_i} + 1 ))
			done
			echo "" 1>&2
			echo "$0: NOTICE: Choose one from them by SdFile variable in ${ConfigFile}." 1>&2
		fi

		if (( ${sd_file_index} > 0 ))
		then
			echo "${sd_file_list[0]}"
			sub_result=0
		fi
		exit ${sub_result}
	)
	sub_result=$?
	[ -n "${debug}" ] && echo "$0.RaspiImgFind: DEBUG: RaspiImgFind() exit." 1>&2
	return ${sub_result}
}

# Generate ethernet MAC address
# RaspiMacGen MacPrefix RandomNumberSeed
function RaspiMacGen() {
	result=1

	[ -n "${debug}" ] && echo "$0.RaspiMacGen: DEBUG: RaspiMacGen $1 $2." 1>&2
	nic_prefix="$1"

	echo "$0: INFO: Create a new MAC address prefixed ${nic_prefix}, wait a moment." 1>&2
	mac_list=( $( arp | awk -F '[[:space:]]+' 'NR>1 {print $3}') )
	nic_incr=0
	while (( ${nic_incr} < 16777216 ))
	do
		nic_hex=$( echo $(hostname)-$2-${nic_incr} | md5sum | cut -b 1-12 )
		# Make a random MAC Address.
		nic_mac="${nic_prefix}:${nic_hex:0:2}:${nic_hex:2:2}:${nic_hex:4:2}"
		if ! echo ${mac_list[*]} | grep -q "${nic_mac}"
		then
			echo "${nic_mac}"
			result=0
			break
		fi
		nic_incr=$(( ${nic_incr} + 1 ))
		if (( ( ${nic_incr} % 1000 ) == 0 ))
		then
			echo "$0: Try ${nic_incr} times, generating a new MAC address." 1>&2
		fi
	done
	return ${result}
}

# Find ethernet bridge interface
function RaspiBridgeFind() {
	result=1

	br_list=( $( ip link show type bridge |\
		grep '^[0-9]\+:' | grep ',[[:space:]]*LOWER_UP' |\
		awk '{print $2}' | cut -d ':' -f 1\
	) )
	if (( ${#br_list[*]} > 1 ))
	then
		echo "$0: NOTICE: There are ${#br_list[*]} bridges linkd-up as follows," 1>&2
		echo "$0: NOTICE:   ${br_list[*]}" 1>&2
		echo "$0: NOTICE: Choose one from them by NicBridge variable in ${ConfigFile}." 1>&2
	fi
	if (( ${#br_list[*]} != 0 ))
	then
		result=0
	fi
	echo ${br_list[0]}
	return $result
}

# Find VNC number which is not in use.
function RaspiVncNumber() {
	result=1
	# VNC number (port) range
	vnc_num_min=10
	vnc_num_max=99
	vnc_num=${vnc_num_min}
	# VNC TCP port base
	vnc_port_base=5900
	vnc_port_min=$(( ${vnc_num_min} + ${vnc_port_base} ))
	vnc_port_max=$(( ${vnc_num_max} + ${vnc_port_base} ))

	vnc_list=( $( ss -O -l -t -n | \
		awk -F '[[:space:]]+' '{print $4}' | sed 's/^.*://' | \
		awk "(\$1 >= ${vnc_port_min} ) && (\$1 <= ${vnc_port_max}) {print \$1}" | sort -n -u \
	) )

	vnc_list_n=${#vnc_list[*]}
	vnc_list_i=0

	while (( ${vnc_num} <= ${vnc_num_max} ))
	do

		if (( ${vnc_list_i} < ${vnc_list_n} ))
		then
			vnc_list_port=${vnc_list[${vnc_list_i}]}
		else
			# No more VNC port in use.
			vnc_list_port=65536
		fi

		vnc_port=$(( ${vnc_num} + ${vnc_port_base} ))

		if (( ${vnc_port} != ${vnc_list_port} ))
		then
			echo ${vnc_num}
			result=0
			break
		fi

		vnc_num=$(( ${vnc_num} + 1 ))
		vnc_list_i=$(( ${vnc_list_i} + 1 ))
	done

	return ${result}
}

# Get remote-viewer version
function RemoteViewerVersion() {
	remote_viewer_ver=$( remote-viewer --version | sed 's/^.*version[[:space:]]*\([0-9.]\+\).*/\1/' )
	result=$?
	if [ -z "${remote_viewer_ver}" ]
	then
		remote_viewer_ver="0.0"
	fi
	echo "${remote_viewer_ver}"
	return ${result}
}

[ -z "${KernelFile}"   ] && KernelFile="bootfs/kernel8.img"
[ -z "${InitrdFile}"   ] && InitrdFile="bootfs/initramfs8"
[ -z "${DtbFile}"      ] && DtbFile="bootfs/bcm2710-rpi-3-b-qemu.dtb"
[ -z "${SdFile}"       ] && SdFile="$( RaspiImgFind )"
[ -z "${NicBridge}"    ] && NicBridge="$( RaspiBridgeFind )"
[ -z "${NicMacFile}"   ] && NicMacFile="net0_mac.txt"
[ -z "${NicMacPrefix}" ] && NicMacPrefix="b8:27:eb"

if [ -z "${NicMac}" ] && [ -f "${NicMacFile}" ]
then
	NicMac=$( cat "${NicMacFile}" )
fi

if [ -z "${NicMac}" ]
then
	NicMac=$( RaspiMacGen "${NicMacPrefix}" "${MyDir}-${SdFile}" )
	if [ -n "${NicMac}" ]
	then
		echo "$0: INFO: Save a new generated MAC address ${NicMac} to ${NicMacFile}."
		echo "${NicMac}" > "${NicMacFile}"
	fi
fi

if [ -z "${DisplayOutput}" ]
then
	DisplayOutput="gtk"
	RemoteViewerSpiceUnix=$( echo "$(RemoteViewerVersion) >= 8.0" | bc )
	if [[ ${RemoteViewerSpiceUnix} == 1 ]]
	then
		DisplayOutput="spice-app"
	fi
fi

echo "$0: INFO: MyDir=${MyDir}"
echo "$0: INFO: KernFile=${KernelFile}"
echo "$0: INFO: InitrdFile=${InitrdFile}"
echo "$0: INFO: DtbFile=${DtbFile}"
echo "$0: INFO: SdFile=${SdFile}"
echo "$0: INFO: NicBridge=${NicBridge}"
echo "$0: INFO: NicMac=${NicMac}"
echo "$0: INFO: DisplayOutput=${DisplayOutput}"

if [ ! -f "${KernelFile}" ]
then
	echo "$0: ERROR: Can not find kernel image file ${KernelFile}."
	exit 1
fi

if [ ! -f "${DtbFile}" ]
then
	echo "$0: ERROR: Can not find DTB file ${DtbFile}."
	exit 1
fi

if [ -z "${SdFile}" ]
then
	echo "$0: ERROR: Can not find Raspberry Pi OS image file *.img *.qcow *.qcow2"
	echo "$0: ERROR: in ${MyDir} directory."
	echo "$0: INFO: Note, Following file name patterns are reserved special purpose,"
	echo "$0: INFO:  swap*.img swap*.qcow swap*.qcow2 - Ignore case, reserved for swap file."
	exit 1
fi

_DriveParam="file=${SdFile}"

if file -L "${SdFile}" | grep -q DOS/MBR
then
	_DriveParam="format=raw,file=${SdFile}"
fi

if file -L "${SdFile}" | grep -q -i QCOW
then
	_DriveFormat=$( QemuImgType "${SdFile}" )
	_DriveParam="format=${_DriveFormat},file=${SdFile}"
fi

if [ -z "${NicBridge}" ]
then
	echo "$0: ERROR: Need network bridge interface."
	echo "$0: INFO: Setup network bridge interface."
	exit 1
fi


if [ -z "${NicMac}" ]
then
	echo "$0: ERROR: Can not generate a new MAC address."
	echo "$0: INFO: Specify an indentical MAC address via file ${NicMacFile}."
	exit 1
fi
