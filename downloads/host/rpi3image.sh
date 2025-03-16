#!/bin/bash

Pwd="$( pwd )"

MyWhich="$( which "$0" )"
MyPath="$( readlink -f "${MyWhich}" )"
MyDir="$( dirname "${MyPath}" )"
MyBase="$( basename "$0" )"
MyBody="${MyBase%.*}"
MyBodyNoSpace="$( echo -n ${MyBody} | tr -s '\000-\040' '_')"
MyBodyNoSuffix="${MyBody%%-*}"

MyTemp=""

RaspiMedia="$1"

if [[ -z "${RaspiMedia}" ]]
then
	echo "$0: Specify Raspberry Pi OS image media path." 1>&2
	exit 1
fi

BootFsFatPoint=""
RootFsExt4Point=""

for MODPROBE in /usr/sbin/modprobe /sbin/modprobe
do
	[ -x "${MODPROBE}" ] && break
done

for QEMU_NBD in /usr/bin/qemu-nbd /bin/qemu-nbd
do
	[ -x "${QEMU_NBD}" ] && break
done

for QEMU_IMG in /usr/bin/qemu-img /bin/qemu-img
do
	[ -x "${QEMU_IMG}" ] && break
done

for PARTPROBE in /usr/sbin/partprobe /sbin/partprobe
do
	[ -x "${PARTPROBE}" ] && break
done

for FILE in /usr/bin/file /bin/file
do
	[ -x "${FILE}" ] && break
done

for SFDISK in /usr/sbin/sfdisk /sbin/sfdisk
do
	[ -x "${SFDISK}" ] && break
done

for FSCK in /usr/sbin/fsck /sbin/fsck
do
	[ -x "${FSCK}" ] && break
done

for GROWPART in /usr/bin/growpart /usr/sbin/growpart /sbin/growpart /bin/growpart
do
	[ -x "${GROWPART}" ] && break
done

for RESIZE2FS in /usr/sbin/resize2fs /sbin/resize2fs
do
	[ -x "${RESIZE2FS}" ] && break
done

for MOUNT in /usr/bin/mount /sbin/mount /bin/mount
do
	[ -x "${MOUNT}" ] && break
done

for UMOUNT in /usr/bin/umount /sbin/umount /bin/umount
do
	[ -x "${UMOUNT}" ] && break
done

for TAR in /usr/bin/tar /bin/tar
do
	[ -x "${TAR}" ] && break
done


# Check Path is used as mount point
# args path
# echo none
# return code 0: mount point, 1: is not mount point.
function PathIsMountPoint() {
	local	point

	if [ -z "$1" ]
	then
		return 1
	fi
	cat /proc/mounts | awk '{print $2}' | while read
	do
		if [ "${REPLY}" == "$1" ]
		then
			echo yes
			break
		fi
	done | grep -q 'yes'
	return $?
}

# At exit procedure
function ExitProc() {
	cd "${Pwd}"

	if PathIsMountPoint "${BootFsFatPoint}"
	then
		${UMOUNT} "${BootFsFatPoint}"
	fi

	if PathIsMountPoint "${RootFsExt4Point}"
	then
		${UMOUNT} "${RootFsExt4Point}"
	fi

	if [ -n "${MyTemp}" ] && [ -d "${MyTemp}" ]
	then
		rm -rf "${MyTemp}"
	fi
}

trap ExitProc EXIT

# Find Temporary Directory.
# args none
# echo Temporary Directory Path, not private, share with others.
function TempDirectoryFind() {
	local Temp

	for Temp in /run/user/$( id -u ) /dev/shm /ramdisk "${TMP}" "${TEMP}" /tmp
	do
		if echo -n "${Temp}" | grep -q '[[:space:]]'
		then
			echo "$0.TempDirectoryFind(): NOTICE: Skip using temporary directory which has space \"${Temp}\"" 1>&2
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
# args none
# echo Random value in hex.
function HashedRamdom() {
	( cat /proc/sys/kernel/random/uuid; date +%s.%N ) | sha256sum | cut -f 1 -d ' '
}

# Generate Tepm path.
# args none
# echo Private Temporary Directory
function TempPathGen() {
	local	my_body="${MyBodyNoSpace}"

	if [ -z "${my_body}" ]
	then
		my_body="rpi3image"
	fi
	echo "$( TempDirectoryFind )/${my_body}-$$-$( HashedRamdom )"
}

MyTemp="$( TempPathGen )"
MyTempReady=

# Prepare Temporal directory.
# args none
# echo none
function TempDirectoryPrepare() {
	if [ -n "${MyTempReady}" ]
	then
		return 0
	fi
	while ! mkdir "${MyTemp}"
	do
		MyTemp="$( TempPathGen )"
	done

	chmod 700 "${MyTemp}"
	[ -n "${debug}" ] && echo "$0.TempDirectoryPrepare(): DEBUG: Create temporal directory. MyTemp=\"${MyTemp}\"" 1>&2
	MyTempReady=yes
	return 0
}

TempDirectoryPrepare
BootFsFatPoint="${MyTemp}/bootfs"
RootFsExt4Point="${MyTemp}/rootfs"

mkdir "${BootFsFatPoint}"
mkdir "${RootFsExt4Point}"

# Find available nbd node
# echo nbdN
function NbdFindAvailableNode() {
	local	i
	local	n
	local	nbd
	local	nbd_path

	n=$( cat /sys/module/nbd/parameters/nbds_max )
	if [ -z "${n}" ]
	then
		return 1
	fi
	i=0
	pushd /sys/block
	while (( ${i} < ${n} ))
	do
		nbd="nbd${i}"
		nbd_path="/sys/block/${nbd}"
		if [ ! -e "${nbd_path}/pid" ]
		then
			echo "${nbd}"
			return 0
		fi
		i=$(( ${i} + 1 ))
	done
	popd
	return 1
}

function LogInt2() {
	local	a
	local	i

	i=0
	a="$1"
	while (( ${a} > 0 ))
	do
		i=$(( ${i} + 1 ))
		a=$(( ${a} >> 1 ))
	done
	echo $i
	return 0
}

function SizeKiMiGi() {
	echo $1 | awk -e '{
		i=0;
		a=$1;
		while (a > 1024) {
			i++;
			a/=1024.0;
		}
		pf="";
		if (i > 0) {
			pf=substr("KMGTPEZYRQ",i,1) "i";
		}
		if (a >= 1000) {
			printf("%4.0f%s\n", a, pf);
		} else {
			if (a >= 100) {
				printf("%3.0f%s\n", a, pf);
			} else {
				if (a >= 10) {
					printf("%3.1f%s\n", a, pf);
				} else {
					printf("%3.2f%s\n", a, pf);
				}
			}
		}
	}'
}

function SizeKMG() {
	echo $1 | awk -e '{
		i=0;
		a=$1;
		while (a > 1000) {
			i++;
			a/=1000.0;
		}
		pf="";
		if (i > 0) {
			pf=substr("KMGTPEZYRQ",i,1);
		}
		if (a >= 1000) {
			printf("%4.0f%s\n", a, pf);
		} else {
			if (a >= 100) {
				printf("%3.0f%s\n", a, pf);
			} else {
				if (a >= 10) {
					printf("%3.1f%s\n", a, pf);
				} else {
					printf("%3.2f%s\n", a, pf);
				}
			}
		}
	}'
}

# Align File size in bytes to 2^n Gibyte
# args FileSizeInBytes
# echo Size Number in Gi Bytes
# return 0
function FileSizeAlignPow2G() {
	local	a
	local	la

	if [[ -z "$1" ]]
	then
		echo "1"
		return 0
	fi

	if (( $1 <= ( 1024 * 1024 * 1024 ) ))
	then
		echo "1" # 1Gibyte
		return 0
	fi

	# Convert size into last offset
	a=$(( $1 - 1 ))
	la=$( LogInt2 ${a} )
	if (( ${la} <= 30 ))
	then
		echo "1" # 1Gibyte
		return 0
	fi
	# note: 2^30 = 1Gi, 2^31 = 2Gi, 2^32 = 4Gi, 2^33 = 8Gi, ...
	echo $(( 1 << ( ${la} - 30 ) ))
	return 0
}

# args path_to_block_device
# echo size_of_block_device_in_bytes
# path_to_block_device /dev/*
function SizeOfBlockDevice() {
	local	count
	local	bs
	local	dev_path
	local	dev_base
	local	sys_block

	if [[ -z "$1" ]]
	then
		echo "$0.SizeOfBlockDevice(): ERROR: No block device path argument." 1>&2
		# no echo
		return 1
	fi

	dev_path="$( readlink -f "$1" )"
	dev_base="$( basename "${dev_path}" )"
	sys_block="/sys/block/${dev_base}"

	if [[ ! -d "${sys_block}" ]]
	then
		echo "$0.SizeOfBlockDevice(): ERROR: Can not find device ${dev_base} in ${sys_block}" 1>&2
		# no echo
		return 1
	fi

	count=$( cat "${sys_block}/size" )
	if [[ -z "${count}" ]]
	then
		echo "$0.SizeOfBlockDevice(): ERROR: No block count in ${sys_block}/size" 1>&2
		# no echo
		return 1
	fi

	echo $(( ${count} * 512 ))
	return 0
}

# args path_to_block_device
# echo LABEL_string
# retrun 0 or 1
function BlkIdLabel() {
	local	label
	local	result

	label="$( blkid -o export "$1" | grep '^LABEL=' | sed 's/^[[:alnum:]_]\+=//' )"
	result=$?

	echo -n "${label}"
	[ -n "${debug}" ] && echo "$0.BlkIdLabel(): DEBUG: Read block device label. dev=\"$1\", label=\"${label}\"" 1>&2
	return ${result}
}

# args path_to_block_device partition_number
# echo LABEL_string
# return 0 or 1
function BlkPartIdLabel() {
	local	part_path

	# Device sd, or hd
	part_path="$1$2"
	if [[ -b "${part_path}" ]]
	then
		BlkIdLabel "${part_path}"
		return $?
	fi

	# Device nbd, mmc
	part_path="$1p$2"
	if [[ -b "${part_path}" ]]
	then
		BlkIdLabel "${part_path}"
		return $?
	fi

	return 1
}


# args path_to_block_device
# echo TYPE_string
# retrun 0 or 1
function BlkIdType() {
	local	type
	local	result

	type="$( blkid -o export "$1" | grep '^TYPE=' | sed 's/^[[:alnum:]_]\+=//' )"
	result=$?

	echo -n "${type}"
	[ -n "${debug}" ] && echo "$0.BlkIdLabel(): DEBUG: Read block device file system. dev=\"$1\", type=\"${type}\"" 1>&2

	return ${result}
}

# args path_to_block_device partition_number
# echo LABEL_string
# return 0 or 1
function BlkPartIdType() {
	local	part_path

	# Device sd or hd
	part_path="$1$2"
	if [[ -b "${part_path}" ]]
	then
		BlkIdType "${part_path}"
		return $?
	fi

	part_path="$1p$2"
	if [[ -b "${part_path}" ]]
	then
		BlkIdType "${part_path}"
		return $?
	fi

	return 1
}

# args path_to_block_device
# echo Not defined
# return ==0: May be Raspberry Pi OS media in device, \
#        !=0: Not Raspberry Pi OS media in device
function BlockDeviceIsRaspiOS() {
	local	dev_path
	local	dev_base
	local	part_label
	local	part_type
	local	part_num

	if [[ -z "$1" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): ERROR: Not argument." 1>&2
		return 1
	fi

	dev_path="$( readlink -f "$1" )"

	if [[ ! -b "${dev_path}" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): ERROR: Not a block device $1" 1>&2
		return 1
	fi

	dev_base="$( basename "${dev_path}" )"

	if ! sudo "${FILE}" -s "${dev_path}" | \
	   grep -q 'DOS/MBR.*1 : ID=0xc.*2 : ID=0x83'
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Not a Raspberry Pi OS image media $1" 1>&2
		return 1
	fi

	part_label="$( BlkPartIdLabel "${dev_path}" 1 )"
	if [[ ! "${part_label}"  == "bootfs" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Partition 1 is \"${part_label}\", not a Raspberry Pi OS image media $1" 1>&2
		return 1
	fi

	part_type="$( BlkPartIdType "${dev_path}" 1 )"
	if [[ ! "${part_type}"  == "vfat" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Partition 1 is ${part_type}, not a Raspberry Pi OS image media $1" 1>&2
		return 1
	fi

	part_label="$(BlkPartIdLabel "${dev_path}" 2)"
	if [[ ! "${part_label}"  == "rootfs" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Partition 2 is \"${part_label}\", not a Raspberry Pi OS image media $1" 1>&2
		return 1
	fi

	part_type="$(BlkPartIdType "${dev_path}" 2)"
	if [[ ! "${part_type}"  == "ext4" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Partition 2 is ${part_type}, not a Raspberry Pi OS image media $1" 1>&2
		return 1
	fi

	part_num=$( sudo "${SFDISK}" -d "${dev_path}" | grep '^/dev/' | wc -l )

	if (( ${part_num} != 2 ))
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: There is ${part_num} partitions, not a Raspberry Pi OS image media $1" 1>&2
		return 1
	fi

	return 0
}

function ShowBlockDevice() {
	local	dev_basename
	local	sys_path
	local	sys_dev_path
	local	size
	local	size_iu
	local	size_du
	local	vendor
	local	model

	dev_basename="$( basename "$1" )"
	sys_path="/sys/block/${dev_basename}"
	sys_dev_path="${sys_path}/device"

	size=$( cat "${sys_path}/size" )
	size=$(( ${size} * 512 ))
	size_iu="$( SizeKiMiGi ${size} )"
	size_du="$( SizeKMG ${size} )"

	vendor=""
	if [[ -f "${sys_dev_path}/vendor" ]]
	then
		vendor=$( cat "${sys_dev_path}/vendor" )
	fi

	model=""
	if [[ -f "${sys_dev_path}/model" ]]
	then
		model=$( cat "${sys_dev_path}/model" )
	fi

	echo "$0: INFO: DEV_PATH=\"$1\"" 1>&2
	echo "$0: INFO: VENDOR=\"${vendor}\"" 1>&2
	echo "$0: INFO: MODEL=\"${model}\"" 1>&2
	echo "$0: INFO: SIZE=${size_iu}/${size_du} bytes" 1>&2
	return 0
}

# args path_to_block_device partition_number
# echo   Not defined
# exit   no
# return 0
function UmountBlockDevicePart() {
	local	part_path

	part_path="${1}${2}"
	if PathIsMountPoint "${part_path}"
	then
		sudo "${UMOUNT}" "${part_path}"
	fi

	part_path="${1}p${2}"
	if PathIsMountPoint "${part_path}"
	then
		sudo "${UMOUNT}" "${part_path}"
	fi

	return 0
}

# args path_to_block_device
# echo   Not defined
# exit   no
# return 0
function UmountRaspiOSMedia() {
	UmountBlockDevicePart "${1}" 1
	UmountBlockDevicePart "${1}" 2

	return 0
}

if [[ -z "${FSCK_TRIES}" ]]
then
	FSCK_TRIES=10
fi

function FsckVolume() {
	local	i
	local	result

	result=0
	i=0
	while (( ${i} < ${FSCK_TRIES} ))
	do
		echo "$0.FsckVolume().loop=$i: INFO: fsck -f -y \"${1}\"" 1>&2
		sudo "${FSCK}" -f -y "${1}" 1>&2
		result=$?
		if (( ${result} == 0 ))
		then
			break
		fi
		i=$(( ${i} + 1 ))
	done
	return ${result}
}

# args path_to_block_device partition_number

function FsckPart() {
	local	part_path

	part_path="${1}${2}"
	if [[ -b "${part_path}" ]]
	then
		FsckVolume "${part_path}"
		return $?
	fi

	part_path="${1}p${2}"
	if [[ -b "${part_path}" ]]
	then
		FsckVolume "${part_path}"
		return $?
	fi

	return 1
}

function FsckRaspiOSMedia() {
	local	result

	FsckPart "$1" 1
	result=$?

	if (( ${result} != 0 ))
	then
		return $?
	fi

	FsckPart "$1" 2
	result=$?

	if (( ${result} != 0 ))
	then
		return $?
	fi

	return 0
}

function GrowPartRaspiOSMedia() {
	local	result
	local	part_path

	result=1

	# Expand rootfs partition
	sudo "${GROWPART}" "$1" 2
	result=$?
	if (( ${result} ! = 0 ))
	then
		return ${result}
	fi

	part_path="${1}2"
	if [[ -b "${part_path}" ]]
	then
		sudo "${RESIZE2FS}" "${part_path}"
		return $?
	fi

	part_path="${1}p2"
	if [[ -b "${part_path}" ]]
	then
		sudo "${RESIZE2FS}" "${part_path}"
		return $?
	fi

	return 1
}

if [[ "${RaspiMedia}" == "?" ]] || \
   [[ "${RaspiMedia}" == "find" ]] || \
   [[ "${RaspiMedia}" == "search" ]] || \
   [[ "${RaspiMedia}" == "suggest" ]]
then
	found=1 # means exit with error.

	for blk in $( ls /dev/sd* | grep -v '[0-9]$' )
	do
		if [[ ! -b "${blk}" ]]
		then
			continue
		fi
		if BlockDeviceIsRaspiOS "${blk}"
		then
			echo "$0: INFO: Found Raspberry Pi OS image media at \"${blk}\"" 1>&2
			found=0
			ShowBlockDevice "${blk}"
		fi
	done
	exit ${found}
fi

if [[ ! -b "${RaspiMedia}" ]]
then
	
	exit 1
fi

TargetKit=""

# note: Currently We use target kit tar.gz to both 32bit and 64bit.

# search target kit tar.gz from current directory 
# and git cloned repository.

for target_kit in "${Pwd}/rpios32bit-target-kit.tar.gz" \
                  "${Pwd}/rpios64bit-target-kit.tar.gz" \
                  "${MyDir}/../downloads/rpios32bit-target-kit.tar.gz" \
                  "${MyDir}/../downloads/rpios64bit-target-kit.tar.gz"
do
	if [[ -f "${target_kit}" ]]
	then
		TargetKit="${target_kit}"
		break
	fi
done

if [[ -z "${TargetKit}" ]]
then
	echo "$0: Can not found target kit tar.gz, rpios32bit-target-kit.tar.gz or rpios64bit-target-kit.tar.gz" 1>&2
	exit 1
fi

RaspiOSImagePrev="${Pwd}/RaspiOS-$$-$( HashedRamdom ).img"

# convert Raspberry Pi OS image media to file.

# sudo "${QEMU_IMG}" convert -f raw -O raw  "${RaspiMedia}" "${RaspiOSImagePrev}"
