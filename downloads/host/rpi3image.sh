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
ProbeCommand DD coreutils		/usr/bin/dd /bin/dd /usr/sbin/dd
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
ProbeCommand WC coreutils		/usr/bin/wc /bin/wc /usr/sbin/wc
ProbeCommand TAR tar			/usr/bin/tar /bin/tar /usr/sbin/tar
ProbeCommand DTC device-tree-compiler	/usr/bin/dtc /bin/dtc /usr/sbin/dtc
ProbeCommand GAWK gawk			/usr/bin/gawk /bin/gawk /usr/bin/awk /bin/awk /usr/sbin/awk /sbin/awk
ProbeCommand PATCH patch		/usr/bin/patch /bin/patch /usr/sbin/patch
ProbeCommand TOUCH coreutils		/usr/bin/touch /bin/touch /usr/sbin/touch
ProbeCommand CHMOD coreutils		/usr/bin/chmod /bin/chmod /usr/sbin/chmod
ProbeCommand CHOWN coreutils		/usr/bin/chown /bin/chown /usr/sbin/chown
ProbeCommand STAT coreutils		/usr/bin/stat /bin/stat /usr/sbin/stat
# Will be use
ProbeCommand FATCAT fatcat		/usr/bin/fatcat /bin/fatcat /usr/sbin/fatcat /sbin/fatcat
ProbeCommand ZCATR gzip			/usr/bin/zcat /bin/zcat /usr/sbin/zcat /sbin/zcat
ProbeCommand STRINGS binutils		/usr/bin/strings /bin/strings /usr/sbin/strings /sbin/strings
ProbeCommand HEAD coreutils		/usr/bin/head /bin/head /usr/sbin/head /sbin/head
ProbeCommand DATE coreutils		/usr/bin/date /bin/date /usr/sbin/date /sbin/date
ProbeCommand CMP diffutils		/usr/bin/cmp /bin/cmp /usr/sbin/cmp /sbin/cmp

if [[ -n "${BASENAME}" ]]
then
	MyBase="$( "${BASENAME}" "$0" )"
else
	MyBase="$0"
fi

if (( ${#ReqPackageList[@]} > 0 ))
then
	echo "${MyBase}: INFO: Need following package(s)." 1>&2
	echo "${MyBase}: INFO:   ${ReqPackageList[@]}" 1>&2
	echo "${MyBase}: HELP: To install package(s), run following command." 1>&2
	echo "${MyBase}: HELP:   sudo apt install ${ReqPackageList[@]}" 1>&2
	exit 1
fi

Pwd="$( "${PWD}" )"

if [[ -n "${SUDO_UID}" ]]
then
	IdUser=${SUDO_UID}
else
	IdUser="$( "${ID}" -u )"
fi

if [[ -n "${SUDO_GID}" ]]
then
	IdGroup=${SUDO_GID}
else
	IdGroup="$( "${ID}" -g )"
fi

MyWhich="$( "${WHICH}" "$0" )"
MyPath="$( "${READLINK}" -f "${MyWhich}" )"
MyDir="$( "${DIRNAME}" "${MyPath}" )"
MyBody="${MyBase%.*}"
MyBodyNoSpace="$( echo -n ${MyBody} | "${TR}" -s '\000-\040' '_')"
MyBodyNoSuffix="${MyBody%%-*}"

RaspiOSImagePrefix="raspios"

function Help() {
	"${CAT}" << EOF
${MyBase}: HELP: Command line:
${MyBase}: HELP:   "${MyBase}" [-s ImageFileSizeInGbyte] \\
${MyBase}: HELP:     [-o ImagePath] [-f] [-h] \\
${MyBase}: HELP:     [/dev/RaspberryPiMedia]
${MyBase}: HELP:
${MyBase}: HELP: -s number Image file size in Gibytes. It should be
${MyBase}: HELP:           power of 2 and larger or equal to
${MyBase}: HELP:           Raspberry PiOSmedia capacity.
${MyBase}: HELP:           Without this option, resize image file
${MyBase}: HELP:           size upto the smallest number of power
${MyBase}: HELP:           of 2 Gibytes size which is larger or equal
${MyBase}: HELP:           to Raspberry Pi OS media capacity.
${MyBase}: HELP: -o path   Image file or directory path to store
${MyBase}: HELP:           media image.
${MyBase}: HELP:           Without this option, image file is stored
${MyBase}: HELP:           into current directory see more details in
${MyBase}: HELP:           following text.
${MyBase}: HELP: -m        Migrate working SD card to qemu.
${MyBase}: HELP:           Create qcow2 output image file.
${MyBase}: HELP: -x [debug_specs,...] Specify debug options.
${MyBase}: HELP:             debug: Print debug messages.
${MyBase}: HELP:             copy_only: Do not modify image file.
${MyBase}: HELP: -f        Force overwrite existing file(s).
${MyBase}: HELP: -h        Show help.
${MyBase}: HELP:
${MyBase}: HELP: Copy the Raspberry Pi OS media at /dev/RaspberryPiMedia
${MyBase}: HELP: to virtual machine image files.
${MyBase}: HELP: By default, files are stored into current directory.
${MyBase}: HELP: When the option -o ImagePath is specified. Outputs are
${MyBase}: HELP: stored according to ImagePath points to as flollows,
${MyBase}: HELP: * ImagePath is a file
${MyBase}: HELP:   * Store Raspberry Pi OS image into file ImagePath
${MyBase}: HELP:   * Store device tree blobs into
${MyBase}: HELP:     \$(dirname ImagePath)/bootfs
${MyBase}: HELP: * ImagePath is a directory
${MyBase}: HELP:   * Store Raspberry Pi OS image into
${MyBase}: HELP:     ImagePath/${RaspiOSImagePrefix}-OSBits-SerialNumber.{img|qcow2}
${MyBase}: HELP:   * Store device tree blobs into ImagePath/bootfs
${MyBase}: HELP: * Not specified the -o option
${MyBase}: HELP:   * Store Raspberry Pi OS image into
${MyBase}: HELP:     ./${RaspiOSImagePrefix}-OSBits-SerialNumber.{img|qcow2}
${MyBase}: HELP:   * Store device tree blobs into ./bootfs
${MyBase}: HELP:
${MyBase}: HELP: To find Raspberry Pi OS image media path,
${MyBase}: HELP: run as follows.
${MyBase}: HELP:   "$0" find
EOF
	exit 1
}

DtRpi3BName="bcm2710-rpi-3-b"
DtRpi3BNameQemu="bcm2710-rpi-3-b-qemu"

NBDDisconnectWait1=3
NBDDisconnectWait2=5

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
		echo "${MyBase}.PathIsMountPoint(): WARNING: No argument." 1>&2
		return 1
	fi
	"${GAWK}" '{print $2}' /proc/mounts  | while read
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
			echo "${MyBase}.TempDirectoryFind(): NOTICE: Skip using temporary directory which has one or more spaces \"${Temp}\"." 1>&2
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
	local	result

	if [[ -z "${my_body}" ]]
	then
		my_body="rpi3image"
	fi

	my_temp="$( "${MKTEMP}" -d -p "$( TempDirectoryFind )" "${my_body}-$$-XXXXXXXXXX" )"
	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}.TempPathGen(): ERROR: Can not create temporary directory at \"${TempDirectoryFind}\"." 1>&2
		return $?
	fi

	"${CHMOD}" 700 "${my_temp}"
	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}.TempPathGen(): ERROR: Can not change \"${my_temp}\" mode to 700." 1>&2
		return ${result}
	fi

	echo "${my_temp}"
	return 0
}

OptionForce=""
OptionSize=""
OptionOutput=""
OptionMigrate=""

if [[ -z "${Debug}" ]]
then
	if [[ -n "${debug}" ]]
	then
		# Defined debug environment value, use it.
		Debug="${debug}"
	else
		Debug=""
	fi
fi
DebugCopyOnly=""

while getopts "fs:o:mx:h" OPT
do
	case "${OPT}" in
	(f)
		OptionForce="yes"
		;;
	(s)
		OptionSize="${OPTARG}"
		;;
	(o)
		OptionOutput="${OPTARG}"
		;;
	(m)
		OptionMigrate="migrate"
		;;
	(x)
		# Debug option
		for debug_spec in ${OPTARG/,/}
		do
			case "${debug_spec}" in
			(debug)
				Debug="y"
				;;
			(copy_only)
				DebugCopyOnly="y"
				;;
			(*)
				echo "${MyBase}: WARNING: Unknown debug specifier \"${debug_spec}\"." 1>&2
				;;
			esac
		done
		;;
	(h)
		Help
		;;
	(*)
		echo "${MyBase}: ERROR: Invalid option -${OPT}." 1>&2
		Help
		;;
	esac
done

shift $(( ${OPTIND} - 1 ))

RaspiMedia="$1"

if [[ -z "${RaspiMedia}" ]]
then
	echo "${MyBase}: ERROR: Specify Raspberry Pi OS image media path." 1>&2
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
	[[ -n "${Debug}" ]] && echo "${MyBase}: DEBUG: Check log2 calculation log2(${OptionSizeNum})=${OptionSizeNumLog2}" 1>&2
	if (( ${OptionSizeNum} != ( 1 << ${OptionSizeNumLog2} ) ))
	then
		echo "${MyBase}: ERROR: The number of -s ${OptionSize} should be power of 2." 1>&2
		exit 1
	fi
fi

OptionOutputDirectory=""
OptionOutputBaseName=""
if [[ -z "${OptionMigrate}" ]]
then
	OptionOutputFormat="raw"
	OptionOutputExt="img"
	OptionOutputCompression=""
else
	OptionOutputFormat="qcow2"
	OptionOutputExt="qcow2"
	OptionOutputCompression="-c"
fi
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
			echo "${MyBase}: NOTICE: Directory \"${OptionOutput}\" does not exist, will be created." 1>&2
		else
			OptionOutputBaseName="$( "${BASENAME}" "${OptionOutput}" )"
			case "${OptionOutputBaseName@L}" in
			(*img)
				OptionOutputFormat="raw"
				OptionOutputCompression=""
				OptionOutputExt="${OptionOutputBaseName##*.}"
				;;
			(*qcow)
				echo "${OptionOutput}: ERROR: Not supported qcow file format, it does not support resize." 1>&2
				exit 1
				;;
			(*qcow2)
				OptionOutputFormat="qcow2"
				OptionOutputCompression="-c"
				OptionOutputExt="qcow2"
				;;
			(*)
				echo "${OptionOutput}: ERROR: Not supported file format." 1>&2
				exit 1
				;;
			esac
			OptionOutputDirName="$( "${DIRNAME}" "${OptionOutput}" )"
			if [[ ! -d "${OptionOutputDirName}" ]]
			then
				echo "${MyBase}: NOTICE: Directory \"${OptionOutputDirName}\" does not exist, will be created." 1>&2
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
		echo "${MyBase}: WARNING: Overwrite existing file or directory \"${OptionOutput}\"." 1>&2
		may_overwrite="yes"
	fi

	if [[ -e "${OptionOutputDirectory}/bootfs" ]] || [[ -e "${OptionOutputDirectoryCanonic}/bootfs" ]]
	then
		echo "${MyBase}: WARNING: Overwrite existing file or directory \"${OptionOutputDirectory}/bootfs\"." 1>&2
		may_overwrite="yes"
	fi

	if [[ -z "${OptionForce}" ]] && [[ -n "${may_overwrite}" ]]
	then
		echo "${MyBase}: HELP: Use -f option to overwrite existing files and/or directories." 1>&2
		exit 1
	fi
fi

GitCloned=""

if [[ -d "${MyDir}/.git" ]]
then
	GitCloned="${MyDir}"
fi

if [[ -z "${GitCloned}" && -d "${MyDir}/../../.git" ]]
then
	GitCloned="$( "${READLINK}" -f "${MyDir}/../../" )"
fi

# Check device is used as mount point
# args path
# echo none
# return code 0: is mount point, 1: is not mount point.
function DeviceIsMounted() {
	if [[ -z "$1" ]]
	then
		echo "${MyBase}.DeviceIsMounted(): WARNING: No argument." 1>&2
		return 1
	fi
	"${GAWK}" '{print $1}' /proc/mounts | while read
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
	echo "${MyBase}: ERROR: Can not create temporary directory." 1>&2
	exit ${result}
fi

echo "${MyBase}: INFO: Use temporary directory \"${MyTemp}\"." 1>&2

BootFsFatPoint="${MyTemp}/bootfs"
RootFsExt4Point="${MyTemp}/rootfs"

"${MKDIR}" -m 700 "${BootFsFatPoint}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not create bootfs mount point. BootFsFatPoint=\"${BootFsFatPoint}\"." 1>&2
	exit ${result}
fi

echo "${MyBase}: INFO: Create bootfs mount point \"${BootFsFatPoint}\"." 1>&2

"${MKDIR}" -m 700 "${RootFsExt4Point}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not create rootfs mount point. RootFsExt4Point=\"${RootFsExt4Point}\"." 1>&2
	exit ${result}
fi

echo "${MyBase}: INFO: Create root mount point \"${RootFsExt4Point}\"." 1>&2

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
	pushd /sys/block > /dev/null 2>&1
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
	popd > /dev/null 2>&1
	return 1
}

function SizeKiMiGi() {
	echo $1 | "${GAWK}" '{
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
	echo $1 | "${GAWK}" '{
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
		echo "${MyBase}.SizeOfBlockDevice(): ERROR: No block device path argument." 1>&2
		# no echo
		return 1
	fi

	dev_path="$( "${READLINK}" -f "$1" )"
	dev_base="$( "${BASENAME}" "${dev_path}" )"
	sys_block="/sys/block/${dev_base}"

	if [[ ! -d "${sys_block}" ]]
	then
		echo "${MyBase}.SizeOfBlockDevice(): ERROR: Can not find device ${dev_base} in ${sys_block}" 1>&2
		# no echo
		return 1
	fi

	count=$( "${CAT}" "${sys_block}/size" )
	if [[ -z "${count}" ]]
	then
		echo "${MyBase}.SizeOfBlockDevice(): ERROR: No block count in ${sys_block}/size" 1>&2
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
	[[ -n "${Debug}" ]] && echo "${MyBase}.BlkIdLabel(): DEBUG: Read block device label. dev=\"$1\", label=\"${label}\"" 1>&2
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
	[[ -n "${Debug}" ]] && echo "${MyBase}.BlkIdLabel(): DEBUG: Read block device file system. dev=\"$1\", type=\"${type}\"" 1>&2

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

# Count partitions on storage
# args  path_to_block_device
# echo  the number of partitons
# return ==0: Success, !=0: Failed
function BlockDevicePartitions() {
	"${SUDO}" "${SFDISK}" -d "${dev_path}" | "${GREP}" '^/dev/' | "${WC}" -l
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
		echo "${MyBase}.BlockDeviceIsRaspiOS(): ERROR: No argument." 1>&2
		return 1
	fi

	dev_path="$( "${READLINK}" -f "$1" )"

	if [[ ! -b "${dev_path}" ]]
	then
		echo "${MyBase}.BlockDeviceIsRaspiOS(): ERROR: Not a block device \"$1\"." 1>&2
		return 1
	fi

	dev_base="$( "${BASENAME}" "${dev_path}" )"

	if ! "${SUDO}" "${FILE}" -s "${dev_path}" | \
	   "${GREP}" -q 'DOS/MBR.*1 : ID=0xc.*2 : ID=0x83'
	then
		echo "${MyBase}.BlockDeviceIsRaspiOS(): INFO: Not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_label="$( BlkPartIdLabel "${dev_path}" 1 )"
	if [[ ! "${part_label}"  == "bootfs" ]]
	then
		echo "${MyBase}.BlockDeviceIsRaspiOS(): INFO: Partition 1 is labeled \"${part_label}\", not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_type="$( BlkPartIdType "${dev_path}" 1 )"
	if [[ ! "${part_type}"  == "vfat" ]]
	then
		echo "${MyBase}.BlockDeviceIsRaspiOS(): INFO: Partition 1 is \"${part_type}\" file system, not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_label="$(BlkPartIdLabel "${dev_path}" 2)"
	if [[ ! "${part_label}"  == "rootfs" ]]
	then
		echo "${MyBase}.BlockDeviceIsRaspiOS(): INFO: Partition 2 is labeled \"${part_label}\", not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_type="$(BlkPartIdType "${dev_path}" 2)"
	if [[ ! "${part_type}"  == "ext4" ]]
	then
		echo "${MyBase}.BlockDeviceIsRaspiOS(): INFO: Partition 2 is \"${part_type}\" file system, not a Raspberry Pi OS image media \"$1\"." 1>&2
		return 1
	fi

	part_num=$( BlockDevicePartitions "$1" )

	if (( ${part_num} != 2 ))
	then
		if [[ -z "${OptionMigrate}" ]]
		then
			echo "${MyBase}.BlockDeviceIsRaspiOS(): INFO: There are ${part_num} partitions, not a Raspberry Pi OS image media \"$1\"." 1>&2
			return 1
		else
			echo "${MyBase}.BlockDeviceIsRaspiOS(): NOTICE: There are ${part_num} partitions in media \"$1\", may be added extra partition." 1>&2
		fi
	fi

	return 0
}

# Convert SCSI device name to /sys/bus/usb/devices/* path
# arg scsi_basename
# echo /sys/bus/usb/devices/* path
# return ==0: Success, !=0: Failed
function ConvertScsiDevToUSBDev() {
	local	sys_block_path
	local	scsi_link
	local	scsi_hcil
	local	scsi_host
	local	sys_host_path
	local	host_link
	local	usb_dev_link
	local	result

	sys_block_path="/sys/block/${1}"
	scsi_link="$( "${READLINK}" "${sys_block_path}/device" )"
	scsi_hcil="$( "${BASENAME}" "${scsi_link}" )"
	scsi_host="$( echo "${scsi_hcil}" | "${GAWK}" -F ':' '{print $1}' )"
	if [[ -z "${scsi_host}" ]]
	then
		return 1
	fi

	sys_host_path="/sys/bus/scsi/devices/host${scsi_host}"
	host_link="$( "${READLINK}" "${sys_host_path}" )"
	if [[ "${host_link}" != */usb[0-9]* ]]
	then
		return 1
	fi
	# Remove hostN
	usb_dev_link="$( "${DIRNAME}" "${host_link}" )"
	# Remove :Configuration.Interface
	usb_dev_link="$( "${DIRNAME}" "${usb_dev_link}" )"
	# Pick USB device path
	usb_dev_link="$( "${BASENAME}" "${usb_dev_link}" )"

	if [[ -z "${usb_dev_link}" ]] || [[ "${usb_dev_link}" != [0-9]* ]]
	then
		return 1
	fi

	echo "/sys/bus/usb/devices/${usb_dev_link}"
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
	local	usb_dev_link

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

	if echo "${vendor}" | "${GREP}" -q '^[[:space:]]*$'
	then
		usb_dev_link="$( ConvertScsiDevToUSBDev "${dev_basename}" )"
		if [[ -d "${usb_dev_link}" ]]
		then
			vendor="$( "${CAT}" "${usb_dev_link}/manufacturer" )"
		fi
	fi

	model=""
	if [[ -f "${sys_dev_path}/model" ]]
	then
		model=$( "${CAT}" "${sys_dev_path}/model" )
	fi

	echo "${MyBase}: INFO: DEV_PATH=\"$1\"" 1>&2
	echo "${MyBase}: INFO: ${1}.VENDOR=\"${vendor}\"" 1>&2
	echo "${MyBase}: INFO: ${1}.MODEL=\"${model}\"" 1>&2
	echo "${MyBase}: INFO: ${1}.SIZE=${size_iu}/${size_du} bytes" 1>&2
	return 0
}

# Unmount block device partition by fully qualified path
# args path_to_block_device_part
# echo   Not defined
# exit   no
# return ==0: Succes, !=0: Failed
function UmountBlockDevicePartPath() {
	if DeviceIsMounted "${1}"
	then
		[[ -n "${Debug}" ]] && echo "${MyBase}.UmountBlockDevicePart().1: DEBUG: umount \"${1}\"" 1>&2
		"${SUDO}" "${UMOUNT}" "${1}"
		return $?
	fi

	return 0
}

# Unmount whole partitions in block device
# args path_to_block_device
# echo   Not defined
# exit   no
# return ==0: Success, !=0: Failed
function UmountBlockDeviceWhole() {
	local	part_path
	local	result

	if [[ -z "${1}" ]]
	then
		echo "${MyBase}.UmountBlockDeviceWhole(): ERROR: Specify path_to_block_device." 1>&2
		return 1
	fi

	for part_path in $( "${SUDO}" "${SFDISK}" -d "${1}" | "${GREP}" '^/dev/' | "${GAWK}" '{print $1}' )
	do
		UmountBlockDevicePartPath "${part_path}"
		result=$?
		if (( ${result} != 0 ))
		then
			return ${result}
		fi
	done

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

		echo "${MyBase}: NOTICE: Waiting partitions become ready NBD \"${1}\"." 1>&2
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
		echo "${MyBase}.FsckVolume().loop=$i: INFO: fsck -f -y \"${1}\"" 1>&2
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
	local	part_path_scsi
	local	part_path_nbd

	part_path_scsi="${1}${2}"
	part_path_nbd="${1}p${2}"

	if [[ -b "${part_path_nbd}" ]]
	then
		[[ -n "${Debug}" ]] && echo "${MyBase}.FsckPart(): DEBUG: Find partition \"${part_path_nbd}\"."
		FsckVolume "${part_path_nbd}"
		return $?
	else
		[[ -n "${Debug}" ]] && echo "${MyBase}.FsckPart(): DEBUG: Not found partition \"${part_path_nbd}\"."
	fi

	if [[ -b "${part_path_scsi}" ]]
	then
		[[ -n "${Debug}" ]] && echo "${MyBase}.FsckPart(): DEBUG: Find partition \"${part_path_scsi}\"."
		FsckVolume "${part_path_scsi}"
		return $?
	else
		[[ -n "${Debug}" ]] && echo "${MyBase}.FsckPart(): DEBUG: Not found partition \"${part_path_scsi}\"."
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
	local	part_path_scsi
	local	part_path_nbd
	local	do_resize

	result=1
	do_resize=""

	# Expand rootfs partition
	"${SUDO}" "${GROWPART}" "$1" 2
	result=$?
	(( ${result} != 0 )) && return ${result}

	part_path_scsi="${1}2"
	part_path_nbd="${1}p2"

	if [[ -b "${part_path_nbd}" ]]
	then
		do_resize="-p2"
		"${SUDO}" "${RESIZE2FS}" "${part_path_nbd}"
		return $?
	fi

	if [[ -b "${part_path_scsi}" ]]
	then
		do_resize="-2"
		"${SUDO}" "${RESIZE2FS}" "${part_path_scsi}"
		return $?
	fi

	if [[ -z "${do_resize}" ]]
	then
		echo "${MyBase}.GrowPartRaspiOSMedia(): ERROR: Device \"${1}\" does not have partition(s)." 1>&2
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

	part_path="${1}p1"
	if [[ -b "${part_path}" ]]
	then
		do_mount="${do_mount}-p1"
		if ! "${SUDO}" "${MOUNT}" -o "${mount_opt}" "${part_path}" "${BootFsFatPoint}"
		then
			result=$?
		fi
	fi

	part_path="${1}1"
	if [[ -z "${do_mount}" ]] && [[ -b "${part_path}" ]]
	then
		do_mount="${do_mount}-1"
		if ! "${SUDO}" "${MOUNT}" -o "${mount_opt}" "${part_path}" "${BootFsFatPoint}"
		then
			result=$?
		fi
	fi

	if [[ -z "${do_mount}" ]]
	then
		echo "${MyBase}.MountRaspiOSMedia(): ERROR: Device \"${1}\" does not have partition 1." 1>&2
		return 1
	fi

	do_mount=""

	part_path="${1}p2"
	if [[ -b "${part_path}" ]]
	then
		do_mount="${do_mount}-p2"
		if ! "${SUDO}" "${MOUNT}"  -o "${mount_opt}" "${part_path}" "${RootFsExt4Point}"
		then
			result=$?
		fi
	fi

	part_path="${1}2"
	if [[ -z "${do_mount}" ]] && [[ -b "${part_path}" ]]
	then
		do_mount="${do_mount}-2"
		if ! "${SUDO}" "${MOUNT}" -o "${mount_opt}" "${part_path}" "${RootFsExt4Point}"
		then
			result=$?
		fi
	fi

	if [[ -z "${do_mount}" ]]
	then
		echo "${MyBase}.MountRaspiOSMedia(): ERROR: Device \"${1}\" does not have partition 2." 1>&2
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
			echo "${MyBase}: INFO: Found Raspberry Pi OS image media at \"${blk}\"." 1>&2
			found=0
			ShowBlockDevice "${blk}"
		fi
	done
	exit ${found}
fi

if [[ ! -d "/sys/module/nbd" ]]
then
	echo "${MyBase}: INFO: Probe nbd kernel module." 1>&2
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
	echo "${MyBase}: ERROR: Not a block device \"${RaspiMedia}\"." 1>&2
	exit 1
fi

if ! BlockDeviceIsRaspiOS "${RaspiMedia}"
then
	echo "${MyBase}: ERROR: Not a Raspberry Pi OS media \"${RaspiMedia}\"." 1>&2
	exit 1
fi

TargetKit=""
TargetKitPostSetup=""
TargetKitRaspiConfigQemu=""

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

TargetKitFilesExec=( \
	/var/local/post-setup.sh \
	/var/local/raspi-config-qemu.sh \
)

TargetKitFiles=( \
	${TargetKitFilesExec[*]} \
	/usr/src/bcm2835-power-off-dkms-1.0/bcm2835_power_off.c \
	/usr/src/bcm2835-power-off-dkms-1.0/dkms.conf \
	/usr/src/bcm2835-power-off-dkms-1.0/Makefile \
)

TargetKitFrom="${GitCloned}/downloads/target"
TargetKitFromGit="yes"

for f in ${TargetKitFiles[*]}
do
	f_from="${TargetKitFrom}${f}"
	if [[ ! -f "${f_from}" ]]
	then
		echo "${MyBase}: NOTICE: Can not find target kit file \"${f_from}\"." 1>&2
		TargetKitFromGit=""
	fi
done

if [[ -z "${DebugCopyOnly}" ]]
then
	if [[ -n "${TargetKitFromGit}" ]]
	then
		echo "${MyBase}: INFO: Use git cloned target kit." 1>&2
	else
		if [[ -n "${TargetKit}" ]]
		then
			echo "${MyBase}: INFO: Use target kit \"${TargetKit}\"." 1>&2
		else
			echo "${MyBase}: ERROR: Can not find target kit .tar.gz or files." 1>&2
			exit 1
		fi
	fi
fi

echo "${MyBase}: INFO: Unmount \"${RaspiMedia}\"." 1>&2

"${SYNC}"

while ! UmountBlockDeviceWhole "${RaspiMediaDev}"
do
	echo "${MyBase}: NOTICE: Retry umount \"${RaspiMedia}\"." 1>&2
	sleep 5
done

if [[ ! -d "${OptionOutputDirectory}" ]]
then
	"${MKDIR}" -m 700 -p "${OptionOutputDirectory}"
	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not create directory \"${OptionOutputDirectory}\"." 1>&2
		exit ${result}
	fi

	"${SUDO}" "${CHOWN}" "${IdUser}:${IdGroup}" "${OptionOutputDirectory}"
	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not change \"${OptionOutputDirectory}\" owner to \"${IdUser}:${IdGroup}\"." 1>&2
		exit ${result}
	fi
fi

RaspiOSImagePreviewReady=""
RaspiOSImagePreview="$( "${MKTEMP}" -p "${OptionOutputDirectory}" "${RaspiOSImagePrefix}-$$-XXXXXXXXXX.${OptionOutputExt}" )"

"${CHMOD}" 600 "${RaspiOSImagePreview}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not change \"${RaspiOSImagePreview}\" access mode into 600." 1>&2
	exit ${result}
fi

# convert Raspberry Pi OS image media to file.

echo "${MyBase}: INFO: Copy Raspberry Pi OS image media \"${RaspiMedia}\" to \"${RaspiOSImagePreview}\"." 1>&2
"${SUDO}" "${QEMU_IMG}" convert -p -f raw -O ${OptionOutputFormat} ${OptionOutputCompression} "${RaspiMedia}" "${RaspiOSImagePreview}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not convert Raspberry OS media \"${RaspiMedia}\" to image file \"${RaspiOSImagePreview}\"." 1>&2
	exit ${result}
fi
RaspiOSImagePreviewReady="yes"

RaspiOSImageSizeConverted=$( "${SUDO}" "${QEMU_IMG}" info "${RaspiOSImagePreview}" \
	| "${GREP}" -i '^virtual[[:space:]]*size' \
	| "${SED}" 's/^.*(\([0-9]\+\).*).*$/\1/'
)
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not get size of Raspberry OS image file \"${RaspiOSImagePreview}\"." 1>&2
	exit ${result}
fi

RaspiOSImageSizeAligned="$( FileSizeAlignPow2G "${RaspiOSImageSizeConverted}" )"

if [[ -n "${OptionSizeNum}" ]]
then
	if (( ${RaspiOSImageSizeAligned} < ${OptionSizeNum} ))
	then
		RaspiOSImageSizeAligned=${OptionSizeNum}
		echo "${MyBase}: NOTICE: Raspberry Pi OS image size will be fixed to ${RaspiOSImageSizeAligned}Gi bytes (by -s ${OptionSize})." 1>&2
	else
		if (( ${RaspiOSImageSizeAligned} > ${OptionSizeNum} ))
		then
			echo "${MyBase}: NOTICE: Raspberry Pi OS image size is larger than ${OptionSizeNum}Gi bytes (by -s ${OptionSize})." 1>&2
			echo "${MyBase}: NOTICE: Use more suitable size." 1>&2
		fi
	fi
fi

echo "${MyBase}: INFO: Resize Raspberry Pi OS image file \"${RaspiOSImagePreview}\" into ${RaspiOSImageSizeAligned}G" 1>&2

"${SUDO}" "${QEMU_IMG}" resize -f ${OptionOutputFormat} "${RaspiOSImagePreview}" "${RaspiOSImageSizeAligned}G"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not resize Raspberry OS image file \"${RaspiOSImagePreview}\"." 1>&2
	exit ${result}
fi

NbdNum=$( "${CAT}" /sys/module/nbd/parameters/nbds_max )
if [[ -z "${NbdNum}" ]]
then
	echo "${MyBase}: ERROR: The kernel NBD module is not ready." 1>&2
	exit 1
fi

i=0
while (( ${i} <= ${NbdNum} ))
do
	if ! NbdNode="$( NbdFindAvailableNode )"
	then
		echo "${MyBase}: ERROR: All NBDs are in use. NbdNum=${NbdNum}" 1>&2
		exit 1
	fi

	NbdDev="/dev/${NbdNode}"

	if "${SUDO}" "${QEMU_NBD}" -f ${OptionOutputFormat} -c "${NbdDev}" "${RaspiOSImagePreview}" 1>&2
	then
		break
	fi
	i=$(( ${i} + 1 ))
done

if (( ${i} > ${NbdNum} ))
then
	echo "${MyBase}: ERROR: Can not connect image file to NBD." 1>&2
	exit 1
fi

echo "${MyBase}: INFO: Connect image \"${RaspiOSImagePreview}\" file to NBD \"${NbdDev}\"." 1>&2

"${SUDO}" "${PARTPROBE}" "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not probe partition NBD \"${NbdDev}\"." 1>&2
	exit ${result}
fi

if ! WaitNbdRaspiOSMedia "${NbdDev}"
then
	echo "${MyBase}: ERROR: Partitions do not become ready NBD \"${NbdDev}\"." 1>&2
	exit 1
fi

FsckRaspiOSMedia "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not finish fsck \"${NbdDev}\" partitions." 1>&2
	exit ${result}
fi

if [[ -z "${OptionMigrate}" ]]
then
	echo "${MyBase}: INFO: Grow rootfs partition (device \"${NbdDev}\" partition 2)." 1>&2

	GrowPartRaspiOSMedia "${NbdDev}"
	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not grow rootfs partition." 1>&2
		exit ${result}
	fi
else
	echo "${MyBase}: NOTICE: Keep rootfs partition (device \"${NbdDev}\" partition 2) size." 1>&2
	echo "${MyBase}: NOTICE: If you want to resize partition, resize or move partitions in virtual machine." 1>&2
fi

echo "${MyBase}: INFO: Mount partitions in Raspberry Pi OS image." 1>&2

MountRaspiOSMedia "${NbdDev}"
result=$?
if (( ${result} != 0))
then
	echo "${MyBase}: ERROR: Can not mount partition(s)." 1>&2
	exit ${result}
fi

RaspiOSArch=$( "${FILE}" "${RootFsExt4Point}/usr/bin/[" | "${SED}" 's!^.*ld-linux-\(.*\)[.]so[.].*$!\1!' )

RaspiOsReleaseBookworm=12
RaspiOsReleaseTrixie=13

RaspiOsReleaseNo=$( "${GREP}" 'VERSION_ID' "${RootFsExt4Point}/etc/os-release" \
	| "${GAWK}" 'BEGIN {FS="="} {print $2}' \
	| "${TR}" -d '"' )

echo "${MyBase}: INFO: Raspberry Pi OS image architecture is \"${RaspiOSArch}\"." 1>&2
echo "${MyBase}: INFO: Raspberry Pi OS image release is \"${RaspiOsReleaseNo}\"." 1>&2

RaspiOSImageTemp=$( "${MKTEMP}" -p "${OptionOutputDirectory}" ${RaspiOSImagePrefix}-XXXXXXXXXX.${OptionOutputExt} )
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not create temporary file in directory \"${OptionOutputDirectory}\"." 1>&2
	exit ${result}
fi

if [[ -z "${OptionOutputBaseName}" ]]
then
	RaspiOSImage="${OptionOutputDirectory}/rpios-0000.${OptionOutputExt}"
	RaspiOSImageSn=0

	while (( ${RaspiOSImageSn} <= 9999 ))
	do
		case "${RaspiOSArch}" in
		(aarch64)
			RaspiOSImage="${OptionOutputDirectory}/${RaspiOSImagePrefix}-64-$(printf "%04d" ${RaspiOSImageSn}).${OptionOutputExt}"
			;;
		(*)
			RaspiOSImage="${OptionOutputDirectory}/${RaspiOSImagePrefix}-32-$(printf "%04d" ${RaspiOSImageSn}).${OptionOutputExt}"
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
			echo "${MyBase}: INFO: Search new Raspberry Pi OS image file \"${RaspiOSImage}\"." 1>&2
		fi
		RaspiOSImageSn=$(( ${RaspiOSImageSn} + 1 ))
	done
	if (( ${RaspiOSImageSn} > 9999 ))
	then
		echo "${MyBase}: ERROR: There are many Raspberry Pi OS image files upto \"${RaspiOSImage}\"." 1>&2
		exit 1
	fi
else
	RaspiOSImage="${OptionOutputDirectory}/${OptionOutputBaseName}"
fi

echo "${MyBase}: INFO: Copy bootfs files." 1>&2

"${CP}" -r "${BootFsFatPoint}" "${OptionOutputDirectory}/"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not copy bootfs partition." 1>&2
	exit ${result}
fi

UserDataFile="${OptionOutputDirectory}/bootfs/user-data"
if [[ -f "${UserDataFile}" ]]
then
	echo "${MyBase}: INFO: Change \"${UserDataFile}\" mode to 700." 1>&2
	"${SUDO}" "${CHMOD}" 600 "${UserDataFile}"
	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not change \"${UserDataFile}\" mode." 1>&2
		exit ${result}
	fi
fi

if [[ -z "${OptionMigrate}" ]]
then
	echo "${MyBase}: INFO: Set bootfs/firstrun.sh permission." 1>&2

	FirstRunMountBootfs="${OptionOutputDirectory}/bootfs/firstrun.sh"

	if [[ -f "${FirstRunMountBootfs}" ]]
	then
		"${SUDO}" "${CHMOD}" 600 "${FirstRunMountBootfs}"
		result=$?
		if (( ${result} != 0 ))
		then
			echo "${MyBase}: ERROR: Can not change mode \"{FirstRunMountBootfs}\"." 1>&2
			exit ${result}
		fi
	else
		echo "${MyBase}: NOTICE: Not found \"${FirstRunMountBootfs}\", skip changing mode." 1>&2
	fi
fi

echo "${MyBase}: INFO: Modify device tree." 1>&2

DtRpi3BNameSource="${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dts"

"${DTC}" -I dtb -O dts -o "${DtRpi3BNameSource}" "${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dtb"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not disassemble device tree blob \"${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dtb\"." 1>&2
	exit ${result}
fi

DtRpi3BNameQemuSource="${OptionOutputDirectory}/bootfs/${DtRpi3BNameQemu}.dts"
DtRpi3BNameQemuBlob="${OptionOutputDirectory}/bootfs/${DtRpi3BNameQemu}.dtb"

"${CP}" -p "${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dts" "${DtRpi3BNameQemuSource}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not copy device tree blob \"${OptionOutputDirectory}/bootfs/${DtRpi3BName}.dts\"." 1>&2
	exit ${result}
fi

if (( ${RaspiOsReleaseNo} >= ${RaspiOsReleaseTrixie} ))
then
	# Trixie or later
	#  Disable bluetooth serial interface
	#  Disable watchdog and also power off device (may be PMIC).
	#  Disable WiFi on SDIO bus.
	"${PATCH}" "${DtRpi3BNameQemuSource}" << EOF
--- bcm2710-rpi-3-b.dts	2025-12-25 10:51:23.364072307 +0900
+++ bcm2710-rpi-3-b-qemu.dts	2025-12-30 22:38:54.216640118 +0900
@@ -567,7 +567,7 @@
 				shutdown-gpios = <0x0b 0x00 0x00>;
 				local-bd-address = [00 00 00 00 00 00];
 				fallback-bd-address;
-				status = "okay";
+				status = "disabled";
 				phandle = <0x3a>;
 			};
 		};
@@ -868,14 +868,19 @@
 		};
 
 		watchdog@7e100000 {
-			compatible = "brcm,bcm2835-pm\0brcm,bcm2835-pm-wdt";
+			compatible = "brcm,bcm2835-pm-power-off";
 			#power-domain-cells = <0x01>;
 			#reset-cells = <0x01>;
-			reg = <0x7e100000 0x114 0x7e00a000 0x24>;
-			reg-names = "pm\0asb";
+			/* PM, ASB, DWC-USB-OTG IP block addresses and sizes.
+			 * The address and size of DWC-USB-OTG is
+			 * aliased with usb@7e980000.
+			 */
+			reg = <0x7e100000 0x114 0x7e00a000 0x24 0x7e980000 0x10000>;
+			reg-names = "pm\0asb\0usb0base";
 			clocks = <0x08 0x15 0x08 0x1d 0x08 0x17 0x08 0x16>;
 			clock-names = "v3d\0peri_image\0h264\0isp";
 			system-power-controller;
+			status = "okay";
 			phandle = <0x2c>;
 		};
 
@@ -991,7 +996,7 @@
 			dma-names = "rx-tx";
 			brcm,overclock-50 = <0x00>;
 			non-removable;
-			status = "okay";
+			status = "disabled";
 			pinctrl-names = "default";
 			pinctrl-0 = <0x1b>;
 			bus-width = <0x04>;
@@ -1002,6 +1007,7 @@
 			wifi@1 {
 				reg = <0x01>;
 				compatible = "brcm,bcm4329-fmac";
+				status = "disabled";
 				phandle = <0x8a>;
 			};
 		};
@@ -1091,7 +1097,7 @@
 				compatible = "brcm,bcm2835-virtgpio";
 				gpio-controller;
 				#gpio-cells = <0x02>;
-				status = "okay";
+				status = "disabled";
 				phandle = <0x3e>;
 			};
 		};
EOF
else
	# Bookworm or earlier
	#  Disable bluetooth serial interface
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
fi

result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not patch device tree source \"${DtRpi3BNameQemuSource}\"." 1>&2
	exit ${result}
fi

"${DTC}" -I dts -O dtb -o "${DtRpi3BNameQemuBlob}" "${DtRpi3BNameQemuSource}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not compile device tree source \"${DtRpi3BNameQemuSource}\"." 1>&2
	exit ${result}
fi

"${CHMOD}" "644" "${DtRpi3BNameQemuBlob}" "${DtRpi3BNameQemuSource}" "${DtRpi3BNameSource}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not change one of or more \"${DtRpi3BNameQemuBlob}\", \"${DtRpi3BNameQemuSource}\", or \"${DtRpi3BNameSource}\" mode to 644." 1>&2
	exit ${result}
fi

"${SUDO}" "${CHOWN}" -R "${IdUser}:${IdGroup}" "${OptionOutputDirectory}/bootfs"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not change owner directory \"${OptionOutputDirectory}/bootfs\" and files." 1>&2
	exit ${result}
fi

if [[ -z "${DebugCopyOnly}" ]]
then
	echo "${MyBase}: INFO: Apply target kit to rootfs." 1>&2

	if [[ -n "${TargetKitFromGit}" ]]
	then
		for f in ${TargetKitFiles[*]}
		do
			f_from="${TargetKitFrom}${f}"
			f_to="${RootFsExt4Point}${f}"
			d_to="${f_to%/*}"

			echo "${MyBase}: INFO: Copy file \"${f_from}\" to \"${f_to}\"." 1>&2

			if [[ ! -d "${d_to}" ]]
			then
				"${SUDO}" "${MKDIR}" -p "${d_to}"

				result=$?
				if (( ${result} != 0 ))
				then
					echo "${MyBase}: ERROR: Can not create directory \"${d_to}\"." 1>&2
					exit ${result}
				fi
			fi

			"${SUDO}" "${CP}" --preserve=timestamps,mode "${f_from}" "${f_to}"

			result=$?
			if (( ${result} != 0 ))
			then
				echo "${MyBase}: ERROR: Can not copy file \"${f_from}\" to \"${f_to}\"." 1>&2
				exit ${result}
			fi
		done

		for f in ${TargetKitFilesExec[*]}
		do
			f_to="${RootFsExt4Point}${f}"

			echo "${MyBase}: INFO: Set execute mode bit \"${f_to}\"." 1>&2

			"${SUDO}" "${CHMOD}" 755 "${f_to}"

			result=$?
			if (( ${result} != 0 ))
			then
				echo "${MyBase}: ERROR: Can not set execute mode bit \"${f_to}\"." 1>&2
				exit ${result}
			fi
		done
	else
		if [[ -n "${TargetKit}" ]]
		then
			"${SUDO}" "${TAR}" -C "${RootFsExt4Point}" --no-same-owner --no-overwrite-dir -xvf "${TargetKit}"

			result=$?
			if (( ${result} != 0 ))
			then
				echo "${MyBase}: ERROR: Can not apply target kit to rootfs." 1>&2
				exit ${result}
			fi
		fi
	fi

	SystemConf="/etc/systemd/system.conf"
	SystemConfMountEtc="${RootFsExt4Point}${SystemConf}"

	echo "${MyBase}: INFO: modify \"${SystemConfMountEtc}\"." 1>&2

	"${SUDO}" "${PATCH}" "${SystemConfMountEtc}" << EOF
--- system.conf.orig 2024-10-11 02:40:53.000000000 +0900
+++ system.conf 2025-01-21 11:40:15.555694259 +0900
@@ -43,11 +43,11 @@
 #DefaultTimerAccuracySec=1min
 #DefaultStandardOutput=journal
 #DefaultStandardError=inherit
-#DefaultTimeoutStartSec=90s
+DefaultTimeoutStartSec=400s
 #DefaultTimeoutStopSec=90s
 #DefaultTimeoutAbortSec=
-#DefaultDeviceTimeoutSec=90s
-#DefaultRestartSec=100ms
+DefaultDeviceTimeoutSec=400s
+DefaultRestartSec=2000ms
 #DefaultStartLimitIntervalSec=10s
 #DefaultStartLimitBurst=5
 #DefaultEnvironment=
EOF

	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not patch \"${SystemConfMountEtc}\"." 1>&2
		exit ${result}
	fi

	LightdmService="/etc/systemd/system/lightdm.service"
	LightdmServiceMountEtc="${RootFsExt4Point}${LightdmService}"
	LightdmServiceMountLib="${RootFsExt4Point}${LightdmService/etc/lib}"

	echo "${MyBase}: INFO: Place modified systemd unit file \"${LightdmServiceMountEtc}\"." 1>&2

	"${SUDO}" "${CP}" "${LightdmServiceMountLib}" "${LightdmServiceMountEtc}"

	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not copy \"${LightdmServiceMountLib}\" to \"${LightdmServiceMountEtc}\"." 1>&2
		exit ${result}
	fi

	"${SUDO}" "${CHMOD}" 644 "${LightdmServiceMountEtc}"

	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not change \"${LightdmServiceMountEtc}\" mode to 644." 1>&2
		exit ${result}
	fi

	"${SUDO}" "${PATCH}" "${LightdmServiceMountEtc}" << EOF
--- /lib/systemd/system/lightdm.service	2025-03-15 00:02:00.000000000 +0900
+++ /etc/systemd/system/lightdm.service	2025-11-25 13:14:40.222838504 +0900
@@ -1,8 +1,10 @@
 [Unit]
 Description=Light Display Manager
 Documentation=man:lightdm(1)
-After=systemd-user-sessions.service dev-dri-card0.device dev-dri-renderD128.device
-Wants=dev-dri-card0.device dev-dri-renderD128.device
+#After=systemd-user-sessions.service dev-dri-card0.device dev-dri-renderD128.device
+#Wants=dev-dri-card0.device dev-dri-renderD128.device
+After=systemd-user-sessions.service
+Wants=
 
 # replaces plymouth-quit since lightdm quits plymouth on its own
 Conflicts=plymouth-quit.service
EOF

	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not patch \"${LightdmServiceMountEtc}\"." 1>&2
		exit ${result}
	fi

	LightdmConf="/etc/lightdm/lightdm.conf"
	LightdmConfMountEtc="${RootFsExt4Point}${LightdmConf}"

	echo "${MyBase}: INFO: Modify lightdm configuration file \"${LightdmConfMountEtc}\"." 1>&2
	if  (( ${RaspiOsReleaseNo}" >= "${RaspiOsReleaseTrixie} ))
	then
		# Follow Trixie changes.
		# Touch up lightdm.conf
		"${SUDO}" "${PATCH}" "${LightdmConfMountEtc}" << EOF
--- lightdm-orig.conf	2025-11-24 11:09:51.162401933 +0900
+++ lightdm-qemu.conf	2025-12-05 18:42:20.684060125 +0900
@@ -26,7 +26,7 @@
 #lock-memory=true
 #user-authority-in-system-dir=false
 #guest-account-script=guest-account
-#logind-check-graphical=true
+logind-check-graphical=false
 #log-directory=/var/log/lightdm
 #run-directory=/var/run/lightdm
 #cache-directory=/var/cache/lightdm
@@ -99,12 +99,12 @@
 #xdmcp-manager=
 #xdmcp-port=177
 #xdmcp-key=
-greeter-session=pi-greeter-labwc
+greeter-session=pi-greeter-x
 greeter-hide-users=false
 #greeter-allow-guest=true
 #greeter-show-manual-login=false
 #greeter-show-remote-login=true
-user-session=rpd-labwc
+user-session=rpd-x
 #allow-user-switching=true
 #allow-guest=true
 #guest-session=
@@ -120,7 +120,7 @@
 autologin-user=rpi-first-boot-wizard
 #autologin-user-timeout=0
 #autologin-in-background=false
-autologin-session=rpd-labwc
+autologin-session=rpd-x
 #exit-on-failure=false
 
 #
EOF
	else
		# Bookworm or earlier.
		# Touch up lightdm.conf
		"${SUDO}" "${PATCH}" "${LightdmConfMountEtc}" << EOF
--- lightdm.conf.orig	2025-12-20 02:01:00.245755276 +0900
+++ lightdm.conf	2025-12-20 02:08:24.677867337 +0900
@@ -108,12 +108,12 @@
 #xdmcp-key=
 #unity-compositor-command=unity-system-compositor
 #unity-compositor-timeout=60
-greeter-session=pi-greeter-labwc
+greeter-session=pi-greeter
 greeter-hide-users=false
 #greeter-allow-guest=true
 #greeter-show-manual-login=false
 #greeter-show-remote-login=true
-user-session=LXDE-pi-labwc
+user-session=LXDE-pi-x
 #allow-user-switching=true
 #allow-guest=true
 #guest-session=
@@ -129,7 +129,7 @@
 autologin-user=rpi-first-boot-wizard
 #autologin-user-timeout=0
 #autologin-in-background=false
-autologin-session=LXDE-pi-labwc
+autologin-session=LXDE-pi-x
 #exit-on-failure=false
 #fallback-test=
 #fallback-session=
EOF
	fi

	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not apply patch to \"${LightdmConfMountEtc}\"." 1>&2
		exit ${result}
	fi

	XorgConf="/etc/X11/xorg.conf.d/00-fbdev.conf"
	XorgConfMountEtc="${RootFsExt4Point}${XorgConf}"

	echo "${MyBase}: INFO: Create Xorg configuration file \"${XorgConfMountEtc}\"." 1>&2

	# Place 00-fbdev.conf with file configured trixie ready.
	"${SUDO}" "${DD}" "of=${XorgConfMountEtc}" << EOF
Section "Device"
	Identifier "Card0"
	Driver "fbdev"
EndSection

Section "ServerLayout"
	Identifier	"ServerLayout0"
	Screen	0 "QEMUFB"
EndSection

Section	"Screen"
	Identifier	"QEMUFB"
	Device		"Card0"
	Monitor		"QEMUFBPanel"
	DefaultDepth	24
	SubSection	"Display"
		Depth	24
	EndSubSection
EndSection

Section	"Monitor"
	Identifier	"QEMUFBPanel"
	VertRefresh	60
EndSection
EOF

	result=$?
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not place Xorg configuration file \"${XorgConfMountEtc}\"." 1>&2
		exit ${result}
	fi

	"${SUDO}" "${CHMOD}" 644 "${XorgConfMountEtc}"
	if (( ${result} != 0 ))
	then
		echo "${MyBase}: ERROR: Can not change \"${XorgConfMountEtc}\" mode to 644." 1>&2
		exit ${result}
	fi

	for f in \
		"${RootFsExt4Point}/etc/systemd/system/multi-user.target.wants/rpi-eeprom-update.service" \
		"${RootFsExt4Point}/etc/systemd/system/multi-user.target.wants/ModemManager.service" \
		"${RootFsExt4Point}/etc/systemd/system/dev-serial1.device.wants/hciuart.service" \
		"${RootFsExt4Point}/etc/systemd/system/sysinit.target.wants/rpi-resize.service"
	do
		if [[ -f "${f}" || -h "${f}" ]]
		then
			echo "${MyBase}: INFO: Disable Raspberry Pi OS service \"${f##*/}\"." 1>&2
			"${SUDO}" "${RM}" "${f}"
			result=$?
			if (( ${result} != 0 ))
			then
				echo "${MyBase}: ERROR: Can not remove \"${f}\"." 1>&2
				exit ${result}
			fi
		else
			[[ -n "${Debug}" ]] && "${MyBase}: DEBUG: Not found \"${f}\"." 1>&2
		fi
	done
else
	echo "${MyBase}: DEBUG: Skip modifying rootfs." 1>&2
fi

echo "${MyBase}: INFO: Remount with read-only mode Raspberry Pi OS image." 1>&2

"${SYNC}"

# Remount Raspberry Pi OS image file with read-only mode
# Expect flush I/O requests.
MountRaspiOSMedia "${NbdDev}" "remount,ro"
result=$?
if (( ${result} != 0))
then
	echo "${MyBase}: ERROR: Can not remount partition(s) with read-only." 1>&2
	exit ${result}
fi

"${SYNC}"

# Expect flush disk I/O, read partition table.
"${SUDO}" "${SFDISK}" -d "${NbdDev}" > /dev/null

"${SYNC}"

echo "${MyBase}: INFO: Unmount Raspberry Pi OS image." 1>&2

UmountBlockDeviceWhole "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not unmount Raspberry Pi OS image." 1>&2
	exit ${result}
fi

echo "${MyBase}: INFO: Disconnect Raspberry Pi OS image from NBD." 1>&2

"${SYNC}"
"${SLEEP}" "${NBDDisconnectWait1}"
"${SYNC}"
"${SLEEP}" "${NBDDisconnectWait2}"

"${SUDO}" "${QEMU_NBD}" -d "${NbdDev}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not disconnect Raspberry Pi OS image." 1>&2
	exit ${result}
fi

echo "${MyBase}: INFO: Rename Raspberry Pi OS image file." 1>&2

"${SUDO}" "${MV}" -f "${RaspiOSImagePreview}" "${RaspiOSImage}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not rename \"${RaspiOSImagePreview}\" to \"${RaspiOSImage}\" Raspberry Pi OS image file." 1>&2
	exit ${result}
fi

"${SUDO}" "${CHOWN}" "${IdUser}:${IdGroup}" "${RaspiOSImage}"
result=$?
if (( ${result} != 0 ))
then
	echo "${MyBase}: ERROR: Can not change file \"${RaspiOSImage}\" owner to ${IdUser}:${IdGroup}." 1>&2
	exit ${result}
fi

echo "${MyBase}: INFO: Created Raspberry Pi OS image file \"${RaspiOSImage}\"." 1>&2
if [[ "${RaspiOSArch}" == "aarch64" ]]
then
	echo "${MyBase}: INFO: Created Raspberry Pi Model 3B device tree file \"${DtRpi3BNameQemuBlob}\"." 1>&2
fi

if (( ${RaspiOsReleaseNo} >= ${RaspiOsReleaseTrixie} ))
then
	echo "${MyBase}: INFO: Next, run \"${MyDir}/rpi3vm64-1st.sh\" ." 1>&2
else
	echo "${MyBase}: INFO: Next, run \"${MyDir}/rpi3vm64-1st.sh\" ." 1>&2
fi

exit 0
