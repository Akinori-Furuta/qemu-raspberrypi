#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause
# Update bootfs/kernel7.img and bootfs/Initramfs7 from SDCard/eMMC
# image file SdFile.

export PATH=/usr/local/sbin:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin

MyWhich="$( which "$0" )"
MyPath="$( readlink -f "${MyWhich}" )"
MyDir="$( dirname "${MyPath}" )"
MyBase="$( basename "$0" )"
MyBody="${MyBase%.*}"
MyBodyNoSuffix="${MyBody%%-*}"

ConfigFile="${MyDir}/${MyBodyNoSuffix}.conf"
CommonFile="${MyDir}/${MyBodyNoSuffix}-common.sh"

BootFsImg=""
Kernel7Temp=""
Initrd7Temp=""

# At exit procedure
# args none
# echo don't care
# return don't care
function ExitProcMainPre() {
	cd "${Pwd}"

	echo "${MyBase}: INFO: Clean temporary files." 1>&2

	[[ -n "${BootFsImg}" ]]   && [[ -e "${BootFsImg}" ]]   && rm -f "${BootFsImg}"
	[[ -n "${Kernel7Temp}" ]] && [[ -e "${Kernel7Temp}" ]] && rm -f "${Kernel7Temp}"
	[[ -n "${Initrd7Temp}" ]] && [[ -e "${Initrd7Temp}" ]] && rm -f "${Initrd7Temp}"
}

if [ -f "${ConfigFile}" ]
then
	echo "${MyBase}: INFO: Load configuration file ${ConfigFile}." 1>&2
	source "${ConfigFile}"
fi

if [ -f "${CommonFile}" ]
then
	echo "${MyBase}: INFO: Load common file ${CommonFile}." 1>&2
	source "${CommonFile}"
fi


[[ -z "${_DriveFormat}" ]]    && _DriveFormat="raw"
[[ -z "${BootBlocks}" ]]      && BootBlocks=16384
[[ -z "${BootFsBlocksMin}" ]] && BootFsBlocksMin=16384
[[ -z "${BootFsBlocksMax}" ]] && BootFsBlocksMax=67108864
[[ -z "${Kernel7Img}" ]]  && Kernel7Img="kernel7.img"
[[ -z "${Initramfs7}" ]]  && Initramfs7="initramfs7"
[[ -z "${Kernel7DdBs}" ]] && Kernel7DdBs=4096

Pwd="$( pwd )"

KernelFileDir="$( dirname "${KernelFile}" )"
InitrdFileDir="$( dirname "${InitrdFile}" )"

if ! BootFsImg="$( mktemp -p "${KernelFileDir}" bootfs-XXXXXXXXXX.img )"
then
	echo "${MyBase}: ERROR: Can not allocate bootfs partition image. directory=\"${KernelFileDir}\"" 1>&2
	exit 1
fi
BootFsBaseName="$( basename "${BootFsImg}" )"

if ! Kernel7Temp="$( mktemp -p "${KernelFileDir}" kernel7-XXXXXXXXXX.img )"
then
	echo "${MyBase}: ERROR: Can not allocate kernel image. directory=\"${KernelFileDir}\"" 1>&2
	exit 1
fi

if ! Initrd7Temp="$( mktemp -p "${InitrdFileDir}" initramfs7-XXXXXXXXXX.img )"
then
	echo "${MyBase}: ERROR: Can not allocate initrd image. directory=\"${InitrdFileDir}\""
	exit 1
fi

echo "${MyBase}: INFO: Dump partition table. if=\"${SdFile}\", of=\"${BootFsImg}\"" 1>&2
if ! qemu-img dd -f "${_DriveFormat}" "if=${SdFile}" bs=512 "count=${BootBlocks}" "of=${BootFsImg}"
then
	echo "${MyBase}: ERROR: Can not extract partition table. if=\"${SdFile}\" of=\"${BootFsImg}\"" 1>&2
	exit 1
fi

bootfs_part_start=0
bootfs_part_sectors=0

if ! pushd "${KernelFileDir}" > /dev/null 2>&1
then
	echo "${MyBase}: ERROR: Can not change directory \"${KernelFileDir}\"" 1>&2
	exit 1
fi
# List Partitions | Extract FAT partition | Remove Boot Flag
bootfs_part=( $( sfdisk -l "${BootFsBaseName}" | grep -i FAT | sed 's/\*//g' ) )
if (( ( $? == 0 ) || ( ${#bootfs_part[*]} > 0 ) ))
then
	bootfs_part_start=$(( ${bootfs_part[1]} + 0 ))
	bootfs_part_sectors=$(( ${bootfs_part[3]} + 0 ))
fi
popd > /dev/null 2>&1

if (( ( ${bootfs_part_start} == 0 ) || ( ${bootfs_part_sectors} == 0 ) ))
then
	echo "${MyBase}: ERROR: Can not find bootfs partition. SdFile=\"${SdFile}\"" 1>&2
	exit 1
fi

CHSSectorMax=63

if ((	( ${bootfs_part_start} < ${CHSSectorMax} ) || \
	( ${bootfs_part_start} >= ${BootFsBlocksMax} ) || \
	( ${bootfs_part_sectors} <  ${BootFsBlocksMin} ) || \
	( ${bootfs_part_sectors} >= ${BootFsBlocksMax} ) \
   ))
then
	echo "${MyBase}: ERROR: May be broken image. SdFile=\"${SdFile}\"" 1>&2
	exit 1
fi

dd_skip=1
dd_bs=$(( ${bootfs_part_start} * 512 ))
dd_count=$(( ( ${bootfs_part_sectors} + ${bootfs_part_start} - 1 ) / ${bootfs_part_start} ))

echo "${MyBase}: INFO: Dump bootfs partition. if=\"${SdFile}\", of=\"${BootFsImg}\"" 1>&2
if ! qemu-img dd -f "${_DriveFormat}" "if=${SdFile}" "bs=${dd_bs}" "skip=${dd_skip}" "count=${dd_count}" "of=${BootFsImg}"
then
	echo "${MyBase}: ERROR: Can not extract bootfs partition. if=\"${SdFile}\" of=\"${BootFsImg}\"" 1>&2
	exit 1
fi

echo "${MyBase}: INFO: bootfs partition information. if=\"${SdFile}\"" 1>&2
if ! fatcat -i "${BootFsImg}"
then
	echo "${MyBase}: ERROR: May be broken FAT BPB. if=\"${SdFile}\"" 1>&2
	exit 1
fi

echo "${MyBase}: INFO: Extract /${Kernel7Img}." 1>&2
if ! fatcat "${BootFsImg}" -r "/${Kernel7Img}"  > "${Kernel7Temp}"
then
	echo "${MyBase}: ERROR: Can not extract /${Kernel7Img}." 1>&2
	exit 1
fi

echo "${MyBase}: INFO: Extract /${Initramfs7}." 1>&2
if ! fatcat "${BootFsImg}" -r "/${Initramfs7}"  > "${Initrd7Temp}"
then
	echo "${MyBase}: ERROR: Can not extract /${Initramfs7}." 1>&2
	exit 1
fi

if cmp -s "${KernelFile}" "${Kernel7Temp}" && cmp -s "${InitrdFile}" "${Initrd7Temp}"
then
	echo "${MyBase}: NOTICE: Current kernel \"${KernelFile}\" and initrd \"${InitrdFile}\" files are same as /bootfs/* files." 1>&2
	exit 1
fi

# Get kernel version string
# arg PathToKernelFile
# echo kernel version string
# return ==0: Success
#        !=0: Failed
function Kernel7Version() {
	local	booting_offset
	local	gzip1f8b_offset
	local	head_count
	local	body_skip

	booting_offset="$( grep -a -o -b -P -i -e 'boot' "$1" )"
	booting_offset="${booting_offset%%:*}"
	if [[ -z "${booting_offset}" ]]
	then
		echo "${MyBase}: ERROR: File \"$1\" may not be a kernel image, not found \"boot\" string." 1>&2
		return 1
	fi
	booting_offset=$(( ${booting_offset} + 0 ))
	if (( ${booting_offset} == 0 ))
	then
		echo "${MyBase}: ERROR: File \"$1\" may not be a kernel image, found \"boot\" string at offset 0." 1>&2
		return 1
	fi

	gzip1f8b_offset="$( LANG=C grep -a -o -b -P -e '\x1f\x8b' "$1" | while read
	do
		gzip1f8b_offset=${REPLY%%:*}
		if (( ${gzip1f8b_offset} > ${booting_offset} ))
		then
			echo "${gzip1f8b_offset}"
			break
		fi
	done )"

	if [[ -z "${gzip1f8b_offset}" ]]
	then
		echo "${MyBase}: ERROR: File \"$1\" may not be a kernel image, not found signature 1F8B after \"boot\" string." 1>&2
		return 1
	fi

	gzip1f8b_offset=$(( ${gzip1f8b_offset} + 0 ))
	if (( ${gzip1f8b_offset} == 0 ))
	then
		echo "${MyBase}: ERROR: File \"$1\" may not be a kernel image, found signature 1F8B at offset 0." 1>&2
		return 1
	fi

	head_count=$(( ${gzip1f8b_offset} % ${Kernel7DdBs} ))
	if (( ${head_count} == 0 ))
	then
		# gzipped part is aligned on block boundary.
		body_skip=$(( ${gzip1f8b_offset} / ${Kernel7DdBs} ))
	else
		# gzipped part is not aligned on block boundary.
		head_count=$(( ${Kernel7DdBs} - ${head_count} ))
		body_skip=$(( ( ${gzip1f8b_offset} + ${Kernel7DdBs} - 1 ) / ${Kernel7DdBs} ))
	fi

	( dd "if=$1" bs=1 skip=${gzip1f8b_offset} count=${head_count} ; \
	  dd "if=$1" bs=${Kernel7DdBs} skip=${body_skip} \
	) | zcat | strings | grep -i '^Linux[[:space:]]\+version' \
	| head -1 | gawk '{print $3}'
	if (( $? != 0 ))
	then
		echo "${MyBase}: ERROR: Can not found kernel version string. file=\"$1\"" 1>&2
		return 1
	fi

	return 0
}

KernelFileName="${KernelFile%.*}"
KernelFileExt="${KernelFile#${KernelFileName}}"
InitrdFileName="${InitrdFile%.*}"
InitrdFileExt="${InitrdFile#${InitrdFileName}}"

KernelFileBackup="${KernelFile}"
InitrdFileBackup="${InitrdFile}"

repeat_count=0
while [[ ( -e "${KernelFileBackup}" ) || ( -e "${InitrdFileBackup}" ) ]]
do
	kernel_version_cur="$( Kernel7Version "${KernelFile}" )"
	if (( ( $? != 0 ) || ( ${repeat_count} > 0 ) ))
	then
		kernel_version_cur="$( date '+%y%m%d%H%M%S' )-$( cat /proc/sys/kernel/random/uuid )"
	fi
	repeat_count=$(( ${repeat_count} + 1 ))
	KernelFileBackup="${KernelFileName}-${kernel_version_cur}${KernelFileExt}"
	InitrdFileBackup="${InitrdFileName}-${kernel_version_cur}${InitrdFileExt}"
done

if [[ -e "${KernelFile}" ]]
then
	echo "${MyBase}: INFO: Backup kernel file \"${KernelFile}\" to \"${KernelFileBackup}\"." 1>&2
	if ! cp -p "${KernelFile}" "${KernelFileBackup}"
	then
		echo "${MyBase}: ERROR: Can not backup \"${KernelFile}\" to \"${KernelFileBackup}\"." 1>&2
		exit 1
	fi
fi

if [[ -e "${InitrdFile}" ]]
then
	echo "${MyBase}: INFO: Backup initrd file \"${InitrdFile}\" to \"${InitrdFileBackup}\"." 1>&2
	if ! cp -p "${InitrdFile}" "${InitrdFileBackup}"
	then
		echo "${MyBase}: ERROR: Can not backup \"${InitrdFile}\" to \"${InitrdFileBackup}\"." 1>&2
		exit 1
	fi
fi

echo "${MyBase}: INFO: Copy kernel file /bootfs/${Kernel7Img} to \"${KernelFile}\"." 1>&2
if ! mv -f "${Kernel7Temp}" "${KernelFile}"
then
	echo "${MyBase}: ERROR: Can not copy kernel file /bootfs/${Kernel7Img} to \"${KernelFile}\"." 1>&2
	exit 1
else
	echo "${MyBase}: INFO: Copy initrd file /bootfs/${Initramfs7} to \"${InitrdFile}\"." 1>&2
	if ! mv -f "${Initrd7Temp}" "${InitrdFile}"
	then
		echo "${MyBase}: ERROR: Can not copy initrd file /bootfs/${Initramfs7} to \"${InitrdFile}\"." 1>&2
		echo "${MyBase}: INFO: Revert kernel file \"${KernelFile}\"." 1>&2
		if ! cp -p "${KernelFileBackup}" "${KernelFile}"
		then
			echo "${MyBase}: ERROR: Can not revert kernel file \"${KernelFile}\"." 1>&2
		fi
		exit 1
	fi
fi
exit 0
