#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause

export PATH=/usr/local/sbin:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin

declare -A ReqPackageList

# Probe command
#  Resolve absolute path or collect package name to suggest
# arg1:   Absolute path variable
# arg2:   Package name
# arg3..: Absolute path list
# echo: Don't care
# return: ==0: Found command, !=0: Not found command
function ProbeCommand() {
	local	cmd_var
	local	package
	local	x

	cmd_var="$1"
	shift
	package="$1"
	shift
	for x in "$@"
	do
		[[ -x "${x}" ]] && break
	done

	if [[ ! -x "${x}" ]]
	then
		ReqPackageList["${package}"]="${package}"
		return 1
	fi

	eval "${cmd_var}"="${x}"
	return 0
}

ProbeCommand WHICH debianutils		/usr/bin/which /bin/which /usr/sbin/which
ProbeCommand ID coreutils		/usr/bin/id /bin/id /usr/sbin/id
ProbeCommand SUDO sudo			/usr/bin/sudo /bin/sudo /usr/sbin/sudo
ProbeCommand CAT coreutils		/usr/bin/cat /bin/cat /usr/sbin/cat
ProbeCommand MODPROBE kmod		/usr/sbin/modprobe /sbin/modprobe /usr/bin/modprobe
ProbeCommand BLKID util-linux		/usr/sbin/blkid /sbin/blkid /usr/bin/blkid
ProbeCommand NBD_CLIENT nbd-client	/usr/sbin/nbd-client /sbin/nbd-client /usr/bin/nbd-client
ProbeCommand QEMU_NBD qemu-utils	/usr/bin/qemu-nbd /bin/qemu-nbd /usr/sbin/qemu-nbd
ProbeCommand QEMU_IMG qemu-utils	/usr/bin/qemu-img /bin/qemu-img /usr/sbin/qemu-img
ProbeCommand PARTPROBE parted		/usr/sbin/partprobe /sbin/partprobe /usr/bin/partprobe
ProbeCommand FILE file			/usr/bin/file /bin/file /usr/sbin/file
ProbeCommand SFDISK fdisk		/usr/sbin/sfdisk /sbin/sfdisk /usr/bin/sfdisk
ProbeCommand FSCK util-linux		/usr/sbin/fsck /sbin/fsck /usr/bin/fsck
ProbeCommand GROWPART cloud-guest-utils	/usr/bin/growpart /usr/sbin/growpart /bin/growpart /sbin/growpart
ProbeCommand RESIZE2FS e2fsprogs	/usr/sbin/resize2fs /sbin/resize2fs /usr/bin/resize2fs
ProbeCommand SYNC coreutils		/usr/bin/sync /bin/sync /usr/sbin/sync
ProbeCommand SLEEP coreutils		/usr/bin/sleep /bin/sleep /usr/sbin/sleep
ProbeCommand MOUNT mount		/usr/bin/mount /sbin/mount /bin/mount
ProbeCommand UMOUNT mount		/usr/bin/umount /sbin/umount /bin/umount
ProbeCommand CP coreutils		/usr/bin/cp /bin/cp /usr/sbin/cp
ProbeCommand LS coreutils		/usr/bin/ls /bin/ls /usr/sbin/ls
ProbeCommand PWD coreutils		/usr/bin/pwd /bin/pwd /usr/sbin/pwd
ProbeCommand BASENAME coreutils		/usr/bin/basename /bin/basename /usr/sbin/basename
ProbeCommand DIRNAME coreutils		/usr/bin/dirname /bin/dirname /usr/sbin/dirname
ProbeCommand READLINK coreutils		/usr/bin/readlink /bin/readlink /usr/sbin/readlink
ProbeCommand MKDIR coreutils		/usr/bin/mkdir /bin/mkdir /usr/sbin/mkdir
ProbeCommand MKTEMP coreutils		/usr/bin/mktemp /bin/mktemp /usr/sbin/mktemp
ProbeCommand MV coreutils		/usr/bin/mv /bin/mv /usr/sbin/mv
ProbeCommand RM coreutils		/usr/bin/rm /bin/rm /usr/sbin/rm
ProbeCommand GREP grep			/usr/bin/grep /bin/grep /usr/sbin/grep
ProbeCommand SED sed			/usr/bin/sed /bin/sed /usr/sbin/sed
ProbeCommand TR coreutils		/usr/bin/tr /bin/tr /usr/sbin/tr
ProbeCommand TAR tar			/usr/bin/tar /bin/tar /usr/sbin/tar
ProbeCommand DTC device-tree-compiler	/usr/bin/dtc /bin/dtc /usr/sbin/dtc
ProbeCommand AWK gawk			/usr/bin/awk /bin/awk /usr/bin/gawk /bin/gawk /usr/sbin/awk /sbin/awk
ProbeCommand PATCH patch		/usr/bin/patch /bin/patch /usr/sbin/patch
ProbeCommand TOUCH coreutils		/usr/bin/touch /bin/touch /usr/sbin/touch
ProbeCommand CHMOD coreutils		/usr/bin/chmod /bin/chmod /usr/sbin/chmod
ProbeCommand CHOWN coreutils		/usr/bin/chown /bin/chown /usr/sbin/chown
ProbeCommand STAT coreutils		/usr/bin/stat /bin/stat /usr/sbin/stat

if (( ${#ReqPackageList[@]} > 0 ))
then
	echo "$0: INFO: Need following package(s)." 1>&2
	echo "$0: INFO:   ${ReqPackageList[@]}" 1>&2
	echo "$0: HELP: To install package(s), run following command." 1>&2
	echo "$0: HELP:   sudo apt install ${ReqPackageList[@]}" 1>&2
	exit 1
fi

Pwd="$( "${PWD}" )"
IdUser="$( "${ID}" -u )"
IdGroup="$( "${ID}" -g )"

MyWhich="$( "${WHICH}" "$0" )"
MyPath="$( "${READLINK}" -f "${MyWhich}" )"
MyDir="$( "${DIRNAME}" "${MyPath}" )"
MyBase="$( "${BASENAME}" "$0" )"
MyBody="${MyBase%.*}"
MyBodyNoSpace="$( echo -n ${MyBody} | "${TR}" -s '\000-\040' '_')"
MyBodyNoSuffix="${MyBody%%-*}"

RaspiOSImagePrefix="raspios"

function Help() {
	"${CAT}" << EOF
$0: HELP: Command line:
$0: HELP:   "$0" [-s ImageFileSizeInGbyte] \\
$0: HELP:     [-o ImagePath] [-f] [-h] \\
$0: HELP:     [/dev/RaspberryPiMedia]
$0: HELP:
$0: HELP: -s number Image file size in Gibytes. It should be
$0: HELP:           power of 2 and larger or equal to
$0: HELP            Raspberry PiOSmedia capacity.
$0: HELP:           Without this option, resize image file
$0: HELP:           size upto the smallest number of power
$0: HELP:           of 2 Gibytes size which is larger or equal
$0: HELP:           to Raspberry Pi OS media capacity.
$0: HELP: -o path   Image file or directory path to store
$0: HELP:           media image.
$0: HELP:           Without this option, image file is stored
$0: HELP:           in current directory see more details in
$0: HELP:           following text.
$0: HELP: -f        Force overwrite existing file(s).
$0: HELP: -h        Show help.
$0: HELP:
$0: HELP: Copy Raspberry Pi OS media at /dev/RaspberryPiMedia
$0: HELP  to virtual machine image files.
$0: HELP: By default, files are stored into current directory.
$0: HELP: When the option -o ImagePath is specified. Outputs are
$0: HELP: stored according to ImagePath points to as flollows,
$0: HELP: * ImagePath is a file
$0: HELP:   * Store Raspberry Pi OS image into file ImagePath
$0: HELP:   * Store device tree blobs into
$0: HELP:     \$(dirname ImagePath)/bootfs
$0: HELP: * ImagePath is a directory
$0: HELP:   * Store Raspberry Pi OS image into
$0: HELP:     ImagePath/${RaspiOSImagePrefix}-OSBits-SerialNumber.img
$0: HELP:   * Store device tree blobs into ImagePath/bootfs
$0: HELP: * Not specified -o option
$0: HELP:   * Store Raspberry Pi OS image into
$0: HELP:     ./${RaspiOSImagePrefix}-OSBits-SerialNumber.img
$0: HELP:   * Store device tree blobs into ./bootfs
$0: HELP:
$0: HELP: To find Raspberry Pi OS image media path,
$0: HELP: run as follows.
$0: HELP:   "$0" find
EOF
	exit 1
}

DtRpi3BName="bcm2710-rpi-3-b"
DtRpi3BNameQemu="bcm2710-rpi-3-b-qemu"

NBDDisconnectWait=3

# Set dummy value before ready to use.

BootFsFatPoint=""
RootFsExt4Point=""
NbdNode=""
NbdDev=""
RaspiOSImagePreviewReady=""
RaspiOSImagePreview=""
RaspiOSImageTemp=""
MyTemp=""

# Check Path is used as mount point
# args path
# echo none
# return code 0: mount point, 1: is not mount point.
function PathIsMountPoint() {
	if [[ -z "$1" ]]
	then
		echo "$0.PathIsMountPoint(): WARNING: No argument." 1>&2
		return 1
	fi
	"${AWK}" '{print $2}' /proc/mounts  | while read
	do
		if [[ "${REPLY}" == "$1" ]]
		then
			echo yes
			break
		fi
	done | "${GREP}" -q 'yes'
	return $?
}

# At exit procedure
# args none
# echo don't care
# return don't care
function ExitProc() {
	cd "${Pwd}"

	if [[ -n "${BootFsFatPoint}" ]] && PathIsMountPoint "${BootFsFatPoint}"
	then
		"${SUDO}" ${UMOUNT} "${BootFsFatPoint}"
	fi

	if [[ -n "${RootFsExt4Point}" ]] && PathIsMountPoint "${RootFsExt4Point}"
	then
		"${SUDO}" ${UMOUNT} "${RootFsExt4Point}"
	fi

	if [[ -n "${NbdDev}" ]]
	then
		"${NBD_CLIENT}" -c "${NbdDev}" && "${SUDO}" "${QEMU_NBD}" -d "${NbdDev}"
	fi

	if [[ -n "${RaspiOSImageTemp}" ]]
	then
		"${RM}" -f "${RaspiOSImageTemp}"
	fi

	if [[ -z "${RaspiOSImagePreviewReady}" ]] && [[ -f "${RaspiOSImagePreview}" ]]
	then
		"${RM}" -f "${RaspiOSImagePreview}"
	fi

	if [[ -n "${MyTemp}" ]] && [[ -d "${MyTemp}" ]]
	then
		"${RM}" -rf "${MyTemp}"
	fi
}

trap ExitProc EXIT

# Find Temporary Directory.
# args none
# echo Temporary Directory Path, not private, share with others.
# return 0
function TempDirectoryFind() {
	local Temp

	for Temp in /run/user/${IdUser} /dev/shm /ramdisk "${TMP}" "${TEMP}" /tmp
	do
		if echo -n "${Temp}" | "${GREP}" -q '[[:space:]]'
		then
			echo "$0.TempDirectoryFind(): NOTICE: Skip using temporary directory which has one or more spaces \"${Temp}\"." 1>&2
			continue
		fi

		if [[ -d "${Temp}" ]] && \
		   [[ -r "${Temp}" ]] && [[ -w "${Temp}" ]] && [[ -x "${Temp}" ]]
		then
			break
		fi
	done
	echo "${Temp}"
	return 0
}

# Generate Tepm path.
# args none
# echo Private Temporary Directory
# return ==0: success, !=0: failed
function TempPathGen() {
	local	my_body="${MyBodyNoSpace}"
	local	my_temp

	if [[ -z "${my_body}" ]]
	then
		my_body="rpi3image"
	fi
	if ! my_temp=$( "${MKTEMP}" -d -p "$( TempDirectoryFind )" "${my_body}-$$-XXXXXXXXXX" )
	then
		return $?
	fi
	"${CHMOD}" 700 "${my_temp}"
	echo "${my_temp}"
	return 0
}

OptionForce=""
OptionSize=""
OptionOutput=""

while getopts "fs:o:h" OPT
do
	case ${OPT} in
	(f)
		OptionForce="yes"
		;;
	(s)
		OptionSize="${OPTARG}"
		;;
	(o)
		OptionOutput="${OPTARG}"
		;;
	(h)
		Help
		;;
	(*)
		echo "$0: ERROR: Invalid option -${OPT}." 1>&2
		Help
		;;
	esac
done

shift $(( ${OPTIND} - 1 ))

RaspiMedia="$1"

if [[ -z "${RaspiMedia}" ]]
then
	echo "$0: ERROR: Specify Raspberry Pi OS image media path." 1>&2
	Help
	exit 1
fi

if [[ "${RaspiMedia}" == "help" ]] ||
   [[ "${RaspiMedia}" == "--help" ]]
then
	Help
	exit 1
fi

RequestFind=""
if [[ "${RaspiMedia}" == "?" ]] || \
   [[ "${RaspiMedia}" == "find" ]] || \
   [[ "${RaspiMedia}" == "scan" ]] || \
   [[ "${RaspiMedia}" == "search" ]] || \
   [[ "${RaspiMedia}" == "suggest" ]]
then
	RequestFind="yes"
fi

# Calculate Log2(integer), round up if fractional part is not zero.
# args integer_value
# echo The number of Log2()
# return ==0: always
function LogInt2Rup() {
	local	a
	local	i
	local	f

	i=0
	a="$1"
	f=0
	while (( ${a} > 1 ))
	do
		if (( ( ${a} & 0x1 ) != 0x0 ))
		then
			f=1
		fi
		a=$(( ${a} >> 1 ))
		i=$(( ${i} + 1 ))
	done
	echo $(( ${i} + ${f} ))
	return 0
}

OptionSizeNum=""
OptionSizeNumLog2=""
if [[ -n "${OptionSize}" ]]
then
	OptionSizeNum=$( echo "${OptionSize}" | "${SED}" 's/[gG][iI]\{0,1\}$//' )
	OptionSizeNumLog2=$( LogInt2Rup "${OptionSizeNum}" )
	[[ -n "${debug}" ]] && echo "$0: DEBUG: Check log2 calculation log2(${OptionSizeNum})=${OptionSizeNumLog2}" 1>&2
	if (( ${OptionSizeNum} != ( 1 << ${OptionSizeNumLog2} ) ))
	then
		echo "$0: The number of -s ${OptionSize} should be power of 2." 1>&2
		exit 1
	fi
fi

OptionOutputDirectory=""
OptionOutputBaseName=""
OptionOutputDirName=""

if [[ -n "${OptionOutput}" ]]
then
	if [[ -d "${OptionOutput}" ]]
	then
		OptionOutputBaseName=""
		OptionOutputDirectory="$( echo "${OptionOutput}" | "${SED}" 's!/*$!!' )"
		OptionOutputDirName="${OptionOutputDirectory}"
	else
		if [[ "${OptionOutput}" == */ ]]
		then
			OptionOutputBaseName=""
			OptionOutputDirectory="$( echo "${OptionOutput}" | "${SED}" 's!/*$!!' )"
			OptionOutputDirName="${OptionOutputDirectory}"
			echo "$0: NOTICE: Directory \"${OptionOutput}\" does not exist, will be created." 1>&2
		else
			OptionOutputBaseName="$( "${BASENAME}" "${OptionOutput}" )"
			OptionOutputDirName="$( "${DIRNAME}"   "${OptionOutput}" )"
			if [[ ! -d "${OptionOutputDirName}" ]]
			then
				echo "$0: NOTICE: Directory \"${OptionOutputDirName}\" does not exist, will be created." 1>&2

			fi
			OptionOutputDirectory="${OptionOutputDirName}"
		fi
	fi
else
	OptionOutputBaseName=""
	OptionOutputDirName="${Pwd}"
	OptionOutputDirectory="${Pwd}"
fi

OptionOutputDirectoryCanonic="$( "${READLINK}" -f "${OptionOutputDirectory}" )"

if [[ -z "${RequestFind}" ]]
then
	may_overwrite=""

	if [[ -n "${OptionOutput}" ]] && [[ -e "${OptionOutput}" ]]
	then
		echo "$0: WARNING: Overwrite existing file or directory \"${OptionOutput}\"." 1>&2
		may_overwrite="yes"
	fi

	if [[ -e "${OptionOutputDirectory}/bootfs" ]] || [[ -e "${OptionOutputDirectoryCanonic}/bootfs" ]]
	then
		echo "$0: WARNING: Overwrite existing file or directory \"${OptionOutputDirectory}/bootfs\"." 1>&2
		may_overwrite="yes"
	fi

	if [[ -z "${OptionForce}" ]] && [[ -n "${may_overwrite}" ]]
	then
		echo "$0: HELP: Use -f option to overwrite existing files and/or directories." 1>&2
		exit 1
	fi
fi

# Check device is used as mount point
# args path
# echo none
# return code 0: is mount point, 1: is not mount point.
function DeviceIsMounted() {
	if [[ -z "$1" ]]
	then
		echo "$0.DeviceIsMounted(): WARNING: No argument." 1>&2
		return 1
	fi
	"${AWK}" '{print $1}' /proc/mounts | while read
	do
		if [[ "${REPLY}" == "$1" ]]
		then
			echo yes
			break
		fi
	done | "${GREP}" -q 'yes'
	return $?
}

MyTemp="$( TempPathGen )"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not create temporary directory." 1>&2
	exit ${result}
fi

echo "$0: INFO: Use temporary directory \"${MyTemp}\"." 1>&2

BootFsFatPoint="${MyTemp}/bootfs"
RootFsExt4Point="${MyTemp}/rootfs"

"${MKDIR}" "${BootFsFatPoint}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not create bootfs mount point. BootFsFatPoint=\"${BootFsFatPoint}\"." 1>&2
	exit ${result}
fi

"${MKDIR}" "${RootFsExt4Point}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not create rootfs mount point. RootFsExt4Point=\"${RootFsExt4Point}\"." 1>&2
	exit ${result}
fi


# Find available nbd node
# echo nbdN
function NbdFindAvailableNode() {
	local	i
	local	n
	local	nbd
	local	nbd_path

	n=$( "${CAT}" /sys/module/nbd/parameters/nbds_max )
	if [[ -z "${n}" ]]
	then
		return 1
	fi
	i=0
	pushd /sys/block 1>&2
	while (( ${i} < ${n} ))
	do
		nbd="nbd${i}"
		nbd_path="/sys/block/${nbd}"
		if [[ ! -e "${nbd_path}/pid" ]]
		then
			echo "${nbd}"
			return 0
		fi
		i=$(( ${i} + 1 ))
	done
	popd 1>&2
	return 1
}

function SizeKiMiGi() {
	echo $1 | "${AWK}" -e '{
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
	echo $1 | "${AWK}" -e '{
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

	la=$( LogInt2Rup $1 )
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
# return ==0: Success, !=0: Failed
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

	dev_path="$( "${READLINK}" -f "$1" )"
	dev_base="$( "${BASENAME}" "${dev_path}" )"
	sys_block="/sys/block/${dev_base}"

	if [[ ! -d "${sys_block}" ]]
	then
		echo "$0.SizeOfBlockDevice(): ERROR: Can not find device ${dev_base} in ${sys_block}" 1>&2
		# no echo
		return 1
	fi

	count=$( "${CAT}" "${sys_block}/size" )
	if [[ -z "${count}" ]]
	then
		echo "$0.SizeOfBlockDevice(): ERROR: No block count in ${sys_block}/size" 1>&2
		# no echo
		return 1
	fi

	echo $(( ${count} * 512 ))
	return 0
}

# Get block device label
# args path_to_block_device
# echo LABEL_string
# retrun ==0: Success or !=0: Failed
function BlkIdLabel() {
	local	label
	local	result

	label="$( "${SUDO}" "${BLKID}" -o export "$1" | "${GREP}" '^LABEL=' | "${SED}" 's/^[[:alnum:]_]\+=//' )"
	result=$?

	echo -n "${label}"
	[[ -n "${debug}" ]] && echo "$0.BlkIdLabel(): DEBUG: Read block device label. dev=\"$1\", label=\"${label}\"" 1>&2
	return ${result}
}

# Get block device partition label
# args path_to_block_device partition_number
# echo LABEL_string
# return ==0: Success or !=0: Failed
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

# Get block device type (file system)
# args path_to_block_device
# echo TYPE_string
# retrun ==0: Success or !=0: Failed
function BlkIdType() {
	local	type
	local	result

	type="$( "${SUDO}" "${BLKID}" -o export "$1" | "${GREP}" '^TYPE=' | "${SED}" 's/^[[:alnum:]_]\+=//' )"
	result=$?

	echo -n "${type}"
	[[ -n "${debug}" ]] && echo "$0.BlkIdLabel(): DEBUG: Read block device file system. dev=\"$1\", type=\"${type}\"" 1>&2

	return ${result}
}

# Get block device partition type (file system)
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

# Check block device may be Raspberry Pi OS media
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

	dev_path="$( "${READLINK}" -f "$1" )"

	if [[ ! -b "${dev_path}" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): ERROR: Not a block device \"$1\"." 1>&2
		return 1
	fi

	dev_base="$( "${BASENAME}" "${dev_path}" )"

	if ! "${SUDO}" "${FILE}" -s "${dev_path}" | \
	   "${GREP}" -q 'DOS/MBR.*1 : ID=0xc.*2 : ID=0x83'
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_label="$( BlkPartIdLabel "${dev_path}" 1 )"
	if [[ ! "${part_label}"  == "bootfs" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Partition 1 is labeled \"${part_label}\", not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_type="$( BlkPartIdType "${dev_path}" 1 )"
	if [[ ! "${part_type}"  == "vfat" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Partition 1 is \"${part_type}\" file system, not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_label="$(BlkPartIdLabel "${dev_path}" 2)"
	if [[ ! "${part_label}"  == "rootfs" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Partition 2 is labeled \"${part_label}\", not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_type="$(BlkPartIdType "${dev_path}" 2)"
	if [[ ! "${part_type}"  == "ext4" ]]
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: Partition 2 is \"${part_type}\" file system, not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_num=$( "${SUDO}" "${SFDISK}" -d "${dev_path}" | "${GREP}" '^/dev/' | wc -l )

	if (( ${part_num} != 2 ))
	then
		echo "$0.BlockDeviceIsRaspiOS(): INFO: There are ${part_num} partitions, not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	return 0
}

# Show block device information
# arg path_to_block_device
# echo human readable information
# return 0
function ShowBlockDevice() {
	local	dev_basename
	local	sys_path
	local	sys_dev_path
	local	size
	local	size_iu
	local	size_du
	local	vendor
	local	model

	dev_basename="$( "${BASENAME}" "$1" )"
	sys_path="/sys/block/${dev_basename}"
	sys_dev_path="${sys_path}/device"

	size=$( "${CAT}" "${sys_path}/size" )
	size=$(( ${size} * 512 ))
	size_iu="$( SizeKiMiGi ${size} )"
	size_du="$( SizeKMG ${size} )"

	vendor=""
	if [[ -f "${sys_dev_path}/vendor" ]]
	then
		vendor=$( "${CAT}" "${sys_dev_path}/vendor" )
	fi

	model=""
	if [[ -f "${sys_dev_path}/model" ]]
	then
		model=$( "${CAT}" "${sys_dev_path}/model" )
	fi

	echo "$0: INFO: DEV_PATH=\"$1\"" 1>&2
	echo "$0: INFO: ${1}.VENDOR=\"${vendor}\"" 1>&2
	echo "$0: INFO: ${1}.MODEL=\"${model}\"" 1>&2
	echo "$0: INFO: ${1}.SIZE=${size_iu}/${size_du} bytes" 1>&2
	return 0
}

# Unmount block device partition
# args path_to_block_device partition_number
# echo   Not defined
# exit   no
# return 0
function UmountBlockDevicePart() {
	local	part_path

	part_path="${1}${2}"
	if DeviceIsMounted "${part_path}"
	then
		[[ -n "${debug}" ]] && echo "$0.UmountBlockDevicePart().1: DEBUG: umount \"${part_path}\"" 1>&2
		"${SUDO}" "${UMOUNT}" "${part_path}"
		return $?
	fi

	part_path="${1}p${2}"
	if DeviceIsMounted "${part_path}"
	then
		[[ -n "${debug}" ]] && echo "$0.UmountBlockDevicePart().2: DEBUG: umount \"${part_path}\"" 1>&2
		"${SUDO}" "${UMOUNT}" "${part_path}"
		return $?
	fi

	return 0
}

# Unmount Raspberry Pi OS media
# args path_to_block_device
# echo   Not defined
# exit   no
# return 0
function UmountRaspiOSMedia() {
	local	result

	if [[ -z "${1}" ]]
	then
		echo "$0.UmountRaspiOSMedia(): ERROR: Specify path_to_block_device." 1>&2
		return 1
	fi

	UmountBlockDevicePart "${1}" 1
	result=$?
	[[ -n "${debug}" ]] && echo "$0.UmountRaspiOSMedia().1: DEBUG: umount \"${1}\" partition 1, result=${result}" 1>&2
	(( ${result} != 0 )) && return ${result}

	UmountBlockDevicePart "${1}" 2
	result=$?
	[[ -n "${debug}" ]] && echo "$0.UmountRaspiOSMedia().2: DEBUG: umount \"${1}\" partition 2, result=${result}" 1>&2
	(( ${result} != 0 )) && return ${result}

	return 0
}

# Wait ready to use NBD partitions
# args path_to_nbd_device
# echo Don't care
# return ==0: Success, !=0: Failed
function WaitNbdRaspiOSMedia() {
	local	i

	i=0

	while [[ ! -b "${1}p1" ]] || [[ ! -b "${1}p2" ]]
	do
		if (( ${i} >= 120 ))
		then
			return 1
		fi

		echo "$0: NOTICE: Waiting partitions become ready NBD \"${1}\"." 1>&2
		i=$(( ${i} + 1 ))
		sleep 1
	done

	return 0
}

if [[ -z "${FSCK_TRIES}" ]]
then
	FSCK_TRIES=10
fi

# fsck block device volume
# args device_path_to_fsck
# echo Don't care
# return ==0: Success, !=0: Failed
function FsckVolume() {
	local	i
	local	result

	result=0
	i=0
	while (( ${i} < ${FSCK_TRIES} ))
	do
		echo "$0.FsckVolume().loop=$i: INFO: fsck -f -y \"${1}\"" 1>&2
		"${SUDO}" "${FSCK}" -f -y "${1}" 1>&2
		result=$?
		(( ${result} == 0 )) && break
		i=$(( ${i} + 1 ))
	done
	return ${result}
}

# fsck block device partition
# args path_to_block_device partition_number
# echo don't care
# return ==0: Success, !=0: Failed
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

# fsck Raspberry Pi OS media (image file)
# args device_path
# echo Not specified
# return ==0: Success, !=0: Failed
function FsckRaspiOSMedia() {
	local	result

	FsckPart "$1" 1
	result=$?
	(( ${result} != 0 )) && return ${result}

	FsckPart "$1" 2
	result=$?
	(( ${result} != 0 )) && return ${result}

	return 0
}

function GrowPartRaspiOSMedia() {
	local	result
	local	part_path
	local	do_resize

	result=1
	do_resize=""

	# Expand rootfs partition
	"${SUDO}" "${GROWPART}" "$1" 2
	result=$?
	(( ${result} != 0 )) && return ${result}

	part_path="${1}2"
	if [[ -b "${part_path}" ]]
	then
		do_resize="-2"
		"${SUDO}" "${RESIZE2FS}" "${part_path}"
		return $?
	fi

	part_path="${1}p2"
	if [[ -b "${part_path}" ]]
	then
		do_resize="-p2"
		"${SUDO}" "${RESIZE2FS}" "${part_path}"
		return $?
	fi

	if [[ -z "${do_resize}" ]]
	then
		echo "$0.GrowPartRaspiOSMedia(): ERROR: Device \"${1}\" does not have partition(s)." 1>&2
	fi

	return 1
}

# Mount Raspberry Pi media or image file
# args path_to_device [mount_option]
# echo don't care
# return ==0: Success, !=0: Failed
function MountRaspiOSMedia() {
	local	result
	local	part_path
	local	mount_opt
	local	do_mount

	result=0

	mount_opt="rw"
	if [[ -n "${2}" ]]
	then
		mount_opt="${2}"
	fi

	do_mount=""

	part_path="${1}1"
	if [[ -b "${part_path}" ]]
	then
		do_mount="${do_mount}-1"
		if ! "${SUDO}" "${MOUNT}" -o "${mount_opt}" "${part_path}" "${BootFsFatPoint}"
		then
			result=$?
		fi
	fi

	part_path="${1}p1"
	if [[ -b "${part_path}" ]]
	then
		do_mount="${do_mount}-p1"
		if ! "${SUDO}" "${MOUNT}" -o "${mount_opt}" "${part_path}" "${BootFsFatPoint}"
		then
			result=$?
		fi
	fi

	if [[ -z "${do_mount}" ]]
	then
		echo "$0.MountRaspiOSMedia(): ERROR: Device \"${1}\" does not have partition 1." 1>&2
		return 1
	fi

	do_mount=""

	part_path="${1}2"
	if [[ -b "${part_path}" ]]
	then
		do_mount="${do_mount}-2"
		if ! "${SUDO}" "${MOUNT}" -o "${mount_opt}" "${part_path}" "${RootFsExt4Point}"
		then
			result=$?
		fi
	fi

	part_path="${1}p2"
	if [[ -b "${part_path}" ]]
	then
		do_mount="${do_mount}-p2"
		if ! "${SUDO}" "${MOUNT}"  -o "${mount_opt}" "${part_path}" "${RootFsExt4Point}"
		then
			result=$?
		fi
	fi

	if [[ -z "${do_mount}" ]]
	then
		echo "$0.MountRaspiOSMedia(): ERROR: Device \"${1}\" does not have partition 2." 1>&2
		return 1
	fi

	return ${result}
}

if [[ -n "${RequestFind}" ]]
then
	found=1 # means exit with error.

	for blk in $( "${LS}" /dev/sd* | "${GREP}" -v '[0-9]$' )
	do
		if [[ ! -b "${blk}" ]]
		then
			continue
		fi
		if BlockDeviceIsRaspiOS "${blk}"
		then
			echo "$0: INFO: Found Raspberry Pi OS image media at \"${blk}\"." 1>&2
			found=0
			ShowBlockDevice "${blk}"
		fi
	done
	exit ${found}
fi

if [ ! -d "/sys/module/nbd" ]
then
	echo "$0: INFO: Probe nbd kernel module." 1>&2
	"${SUDO}" "${MODPROBE}" nbd
	result=$?
	if (( ${result} != 0 ))
	then
		exit ${result}
	fi
	# note: The udev daemon will prepare /dev/nbd* nodes.
	#       While the udev is creating /dev/nbd*,  do some process.
fi

RaspiMediaDev="$( "${READLINK}" -f "${RaspiMedia}" )"

if [[ ! -b "${RaspiMediaDev}" ]]
then
	echo "$0: ERROR: Not a block device \"${RaspiMedia}\"." 1>&2
	exit 1
fi

if ! BlockDeviceIsRaspiOS "${RaspiMedia}"
then
	echo "$0: ERROR: Not a Raspberry Pi OS media \"${RaspiMedia}\"." 1>&2
	exit 1
fi

TargetKit=""

# note: Currently We use one target kit rpios32bit-target-kit.tar.gz
#       to both 32bit and 64bit.

# search target kit tar.gz from current directory 
# and git cloned repository.

for target_kit in "${Pwd}/rpios64bit-target-kit.tar.gz" \
		  "${OptionOutputDirectory}/rpios64bit-target-kit.tar.gz" \
		  "${MyDir}/../downloads/rpios64bit-target-kit.tar.gz" \
		  "${Pwd}/rpios32bit-target-kit.tar.gz" \
		  "${OptionOutputDirectory}/rpios32bit-target-kit.tar.gz" \
		  "${MyDir}/../downloads/rpios32bit-target-kit.tar.gz"
do
	if [[ -f "${target_kit}" ]]
	then
		TargetKit="${target_kit}"
		break
	fi
done

if [[ -z "${TargetKit}" ]]
then
	echo "$0: ERROR: Can not found target kit tar.gz, rpios32bit-target-kit.tar.gz or rpios64bit-target-kit.tar.gz" 1>&2
	exit 1
fi

[[ -n "${debug}" ]] && echo "$0: DEBUG: Found target kit tar.gz. TargetKit=\"${TargetKit}\"." 1>&2

echo "$0: INFO: Unmount \"${RaspiMedia}\"." 1>&2

"${SYNC}"

while ! UmountRaspiOSMedia "${RaspiMediaDev}"
do
	echo "$0: NOTICE: Retry umount \"${RaspiMedia}\"." 1>&2
	sleep 5
done

if [[ ! -d "${OptionOutputDirectory}" ]]
then
	"${MKDIR}" -p "${OptionOutputDirectory}"
	result=$?
	if (( ${result} != 0 ))
	then
		echo "$0: ERROR: Can not create directory \"${OptionOutputDirectory}\"." 1>&2
		exit ${result}
	fi
	chmod 700 "${OptionOutputDirectory}"
	result=$?
	if (( ${result} != 0 ))
	then
		echo "$0: ERROR: Can not change \"${OptionOutputDirectory}\" access mode into 700." 1>&2
		exit ${result}
	fi
fi

RaspiOSImagePreviewReady=""
RaspiOSImagePreview="$( "${MKTEMP}" -p "${OptionOutputDirectory}" "${RaspiOSImagePrefix}-$$-XXXXXXXXXX.img" )"

${CHMOD} 600 "${RaspiOSImagePreview}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not change \"${RaspiOSImagePreview}\" access mode into 600." 1>&2
	exit ${result}
fi

# convert Raspberry Pi OS image media to file.

echo "$0: INFO: Copy Raspberry Pi OS image media \"${RaspiMedia}\" to \"${RaspiOSImagePreview}\"." 1>&2
"${SUDO}" "${QEMU_IMG}" convert -p -f raw -O raw  "${RaspiMedia}" "${RaspiOSImagePreview}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not convert Raspberry OS media \"${RaspiMedia}\" to image file \"${RaspiOSImagePreview}\"." 1>&2
	exit ${result}
fi
RaspiOSImagePreviewReady="yes"

RaspiOSImageSizeConverted=$( ${STAT} -c "%s" "${RaspiOSImagePreview}" )
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not get size of Raspberry OS image file \"${RaspiOSImagePreview}\"." 1>&2
	exit ${result}
fi

RaspiOSImageSizeAligned="$( FileSizeAlignPow2G "${RaspiOSImageSizeConverted}" )"

if [[ -n "${OptionSizeNum}" ]]
then
	if (( ${RaspiOSImageSizeAligned} < ${OptionSizeNum} ))
	then
		RaspiOSImageSizeAligned=${OptionSizeNum}
		echo "$0: NOTICE: Raspberry Pi OS image size will be fixed to ${RaspiOSImageSizeAligned}Gi bytes (by -s ${OptionSize})." 1>&2
	else
		if (( ${RaspiOSImageSizeAligned} > ${OptionSizeNum} ))
		then
			echo "$0: NOTICE: Raspberry Pi OS image size is larger than ${OptionSizeNum}Gi bytes (by -s ${OptionSize})." 1>&2
			echo "$0: NOTICE: Use more suitable size." 1>&2
		fi
	fi
fi

echo "$0: INFO: Resize Raspberry Pi OS image file \"${RaspiOSImagePreview}\" into ${RaspiOSImageSizeAligned}G" 1>&2

"${QEMU_IMG}" resize -f raw "${RaspiOSImagePreview}" "${RaspiOSImageSizeAligned}G"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not resize Raspberry OS image file \"${RaspiOSImagePreview}\"." 1>&2
	exit ${result}
fi

NbdNum=$( "${CAT}" /sys/module/nbd/parameters/nbds_max )
if [[ -z "${NbdNum}" ]]
then
	echo "$0: ERROR: The kernel NBD module is not ready." 1>&2
	exit 1
fi

i=0
while (( ${i} <= ${NbdNum} ))
do
	if ! NbdNode="$( NbdFindAvailableNode )"
	then
		echo "$0: ERROR: All NBDs are in use. NbdNum=${NbdNum}" 1>&2
		exit 1
	fi

	NbdDev="/dev/${NbdNode}"

	if "${SUDO}" "${QEMU_NBD}" -f raw -c "${NbdDev}" "${RaspiOSImagePreview}" 1>&2
	then
		break
	fi
	i=$(( ${i} + 1 ))
done

if (( ${i} > ${NbdNum} ))
then
	echo "$0: ERROR: Can not connect image file to NBD." 1>&2
	exit 1
fi

echo "$0: INFO: Connect image \"${RaspiOSImagePreview}\" file to NBD \"${NbdDev}\"." 1>&2

"${SUDO}" "${PARTPROBE}" "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not probe partition NBD \"${NbdDev}\"." 1>&2
	exit ${result}
fi

if ! WaitNbdRaspiOSMedia "${NbdDev}"
then
	echo "$0: ERROR: Partitions do not become ready NBD \"${NbdDev}\"." 1>&2
	exit 1
fi

FsckRaspiOSMedia "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not finish fsck \"${NbdDev}\" partitions." 1>&2
	exit ${result}
fi

echo "$0: INFO: Grow rootfs partition (device \"${NbdDev}\" partition 2)." 1>&2

GrowPartRaspiOSMedia "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not grow rootfs partition." 1>&2
	exit ${result}
fi

echo "$0: INFO: Mount partitions in Raspberry Pi OS image." 1>&2

MountRaspiOSMedia "${NbdDev}"
result=$?
if (( ${result} != 0))
then
	echo "$0: ERROR: Can not mount partition(s)." 1>&2
	exit ${result}
fi

RaspiOSArch=$( "${FILE}" "${RootFsExt4Point}/usr/bin/[" | "${SED}" 's!^.*ld-linux-\(.*\)[.]so[.].*$!\1!' )

echo "$0: INFO: Raspberry Pi OS image architecture is \"${RaspiOSArch}\"." 1>&2

RaspiOSImageTemp=$( "${MKTEMP}" -p "${OptionOutputDirectory}" ${RaspiOSImagePrefix}-XXXXXXXXXX.img )
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not create temporary file in directory \"${OptionOutputDirectory}\"." 1>&2
	exit ${result}
fi

if [[ -z "${OptionOutputBaseName}" ]]
then
	RaspiOSImage="${OptionOutputDirectory}/rpios-0000.img"
	RaspiOSImageSn=0

	while (( ${RaspiOSImageSn} <= 9999 ))
	do
		case "${RaspiOSArch}" in
		(aarch64)
			RaspiOSImage="${OptionOutputDirectory}/${RaspiOSImagePrefix}-64-$(printf "%04d" ${RaspiOSImageSn}).img"
			;;
		(*)
			RaspiOSImage="${OptionOutputDirectory}/${RaspiOSImagePrefix}-32-$(printf "%04d" ${RaspiOSImageSn}).img"
			;;
		esac
		if [[ ! -f "${RaspiOSImage}" ]]
		then
			"${MV}" -n "${RaspiOSImageTemp}" "${RaspiOSImage}"
			result=$?
			if (( ${result} == 0 ))
			then
				if [[ ! -f "${RaspiOSImageTemp}" ]]
				then
					break
				fi
			fi
		fi
		if (( ( ${RaspiOSImageSn} % 100 ) == 0 ))
		then
			echo "$0: INFO: Search new Raspberry Pi OS image file \"${RaspiOSImage}\"." 1>&2
		fi
		RaspiOSImageSn=$(( ${RaspiOSImageSn} + 1 ))
	done
	if (( ${RaspiOSImageSn} > 9999 ))
	then
		echo "$0: ERROR: There are many Raspberry Pi OS image files upto \"${RaspiOSImage}\"." 1>&2
		exit 1
	fi
else
	RaspiOSImage="${OptionOutputDirectory}/${OptionOutputBaseName}"
fi

echo "$0: INFO: Copy bootfs files." 1>&2

"${SUDO}" "${CP}" -r "${BootFsFatPoint}" "${OptionOutputDirectory}/"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not copy bootfs partition." 1>&2
	exit ${result}
fi

"${SUDO}" "${CHOWN}" -R "${IdUser}:${IdGroup}" "${OptionOutputDirectory}/bootfs"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not change owner bootfs directory and files." 1>&2
	exit ${result}
fi

echo "$0: INFO: Set bootfs/firstrun.sh permission." 1>&2

"${CHMOD}" 600 "${OptionOutputDirectory}/bootfs/firstrun.sh"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not change mode bootfs/firstrun.sh." 1>&2
	exit ${result}
fi

echo "$0: INFO: Modify device tree." 1>&2

"${DTC}" -I dtb -O dts -o "${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dts" "${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dtb"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not disassemble device tree blob \"${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dtb\"." 1>&2
	exit ${result}
fi

DtRpi3BNameQemuSource="${OptionOutputDirectory}/bootfs/${DtRpi3BNameQemu}.dts"
DtRpi3BNameQemuBlob="${OptionOutputDirectory}/bootfs/${DtRpi3BNameQemu}.dtb"

"${CP}" -p "${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dts" "${DtRpi3BNameQemuSource}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not copy device tree blob \"${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dts\"." 1>&2
	exit ${result}
fi

"${PATCH}" "${DtRpi3BNameQemuSource}" << EOF
--- bcm2710-rpi-3-b.dts	2025-03-10 02:10:31.929049869 +0900
+++ bcm2710-rpi-3-b-qemu.dts	2025-03-10 02:10:31.931049840 +0900
@@ -567,7 +567,7 @@
 				shutdown-gpios = <0x0b 0x00 0x00>;
 				local-bd-address = [00 00 00 00 00 00];
 				fallback-bd-address;
-				status = "okay";
+				status = "disabled";
 				phandle = <0x3a>;
 			};
 		};
EOF

result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not patch device tree source \"${DtRpi3BNameQemuSource}\"." 1>&2
	exit ${result}
fi

"${DTC}" -I dts -O dtb -o "${DtRpi3BNameQemuBlob}" "${DtRpi3BNameQemuSource}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not compile device tree source \"${DtRpi3BNameQemuSource}\"." 1>&2
	exit ${result}
fi

echo "$0: INFO: Apply target kit to rootfs." 1>&2

"${SUDO}" tar -C "${RootFsExt4Point}" --no-same-owner --no-overwrite-dir -xvf "${TargetKit}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not apply target kit to rootfs." 1>&2
	exit ${result}
fi

echo "$0: INFO: Remount with read-only mode Raspberry Pi OS image." 1>&2

"${SYNC}"

# Remount Raspberry Pi OS image file with read-only mode
# Expect flush I/O requests.
MountRaspiOSMedia "${NbdDev}" "remount,ro"
result=$?
if (( ${result} != 0))
then
	echo "$0: ERROR: Can not remount partition(s) with read-only." 1>&2
	exit ${result}
fi

"${SYNC}"

# Expect flush disk I/O, read partition table.
"${SUDO}" "${SFDISK}" -d "${NbdDev}" > /dev/null

"${SYNC}"

echo "$0: INFO: Unmount Raspberry Pi OS image." 1>&2

UmountRaspiOSMedia "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not unmount Raspberry Pi OS image." 1>&2
	exit ${result}
fi

echo "$0: INFO: Disconnect Raspberry Pi OS image from NBD." 1>&2

"${SYNC}"
"${SLEEP}" "${NBDDisconnectWait}"
"${SYNC}"
"${SLEEP}" "${NBDDisconnectWait}"

"${SUDO}" "${QEMU_NBD}" -d "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not disconnect Raspberry Pi OS image." 1>&2
	exit ${result}
fi

echo "$0: INFO: Rename Raspberry Pi OS image file." 1>&2

"${MV}" -f "${RaspiOSImagePreview}" "${RaspiOSImage}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not rename \"${RaspiOSImagePreview}\" to \"${RaspiOSImage}\" Raspberry Pi OS image file." 1>&2
	exit ${result}
fi

"${SUDO}" "${CHOWN}" "${IdUser}:${IdGroup}" "${RaspiOSImage}"
result=$?
if (( ${result} != 0 ))
then
	echo "$0: ERROR: Can not change file \"${RaspiOSImage}\" owner to ${IdUser}:${IdGroup}." 1>&2
	exit ${result}
fi

echo "$0: INFO: Created Raspberry Pi OS image file \"${RaspiOSImage}\"." 1>&2
if [[ "${RaspiOSArch}" == "aarch64" ]]
then
	echo "$0: INFO: Created Raspberry Pi Model 3B device tree file \"${DtRpi3BNameQemuBlob}\"." 1>&2
fi
exit 0
