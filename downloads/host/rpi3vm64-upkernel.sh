#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause
# Copy this script to same directory
# which contains SD card Raspberry Pi OS image file *.img and bootfs/*

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
Kernel8Temp=""
Initrd8Temp=""

# At exit procedure
# args none
# echo don't care
# return don't care
function ExitProcMainPre() {
	cd "${Pwd}"

	echo "${MyBase}: INFO: Clean temporary files."

	[[ -n "${BootFsImg}" ]]   && [[ -e "${BootFsImg}" ]]   && rm -f "${BootFsImg}"
	[[ -n "${Kernel8Temp}" ]] && [[ -e "${Kernel8Temp}" ]]  && rm -f "${Kernel8Temp}"
	[[ -n "${Initrd8Temp}" ]] && [[ -e "${Initrd8Temp}" ]] && rm -f "${Initrd8Temp}"
}

if [ -f "${ConfigFile}" ]
then
	echo "${MyBase}: INFO: Load configuration file ${ConfigFile}."
	source "${ConfigFile}"
fi

if [ -f "${CommonFile}" ]
then
	echo "${MyBase}: INFO: Load common file ${CommonFile}."
	source "${CommonFile}"
fi


[[ -z "${_DriveFormat}" ]]    && _DriveFormat="raw"
[[ -z "${BootBlocks}" ]]      && BootBlocks=16384
[[ -z "${BootFsBlocksMin}" ]] && BootFsBlocksMin=16384
[[ -z "${BootFsBlocksMax}" ]] && BootFsBlocksMax=67108864
[[ -z "${Kernel8Img}" ]] && Kernel8Img=kernel8.img
[[ -z "${Initramfs8}" ]] && Initramfs8=initramfs8

Pwd="$( pwd )"

KernelFileDir="$( dirname "${KernelFile}" )"
InitrdFileDir="$( dirname "${InitrdFile}" )"

if ! BootFsImg="$( mktemp -p "${KernelFileDir}" bootfs-XXXXXXXXXX.img )"
then
	echo "${MyBase}: ERROR: Can not allocate bootfs partition image. directory=\"${KernelFileDir}\""
	exit 1
fi
BootFsBaseName="$( basename "${BootFsImg}" )"

if ! Kernel8Temp="$( mktemp -p "${KernelFileDir}" kernel8-XXXXXXXXXX.img )"
then
	echo "${MyBase}: ERROR: Can not allocate kernel image. directory=\"${KernelFileDir}\""
	exit 1
fi

if ! Initrd8Temp="$( mktemp -p "${InitrdFileDir}" initramfs8-XXXXXXXXXX.img )"
then
	echo "${MyBase}: ERROR: Can not allocate initrd image. directory=\"${InitrdFileDir}\""
	exit 1
fi


echo "${MyBase}: INFO: Dump partition table. if=\"${SdFile}\", of=\"${BootFsImg}\""
if ! qemu-img dd -f "${_DriveFormat}" "if=${SdFile}" bs=512 "count=${BootBlocks}" "of=${BootFsImg}"
then
	echo "${MyBase}: ERROR: Can not extract partition table. if=\"${SdFile}\" of=\"${BootFsImg}\""
	exit 1
fi

bootfs_part_start=0
bootfs_part_sectors=0

if ! pushd "${KernelFileDir}" > /dev/null 2>&1
then
	echo "${MyBase}: ERROR: Can not change directory \"${KernelFileDir}\""
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
	echo "${MyBase}: ERROR: Can not find bootfs partition. SdFile=\"${SdFile}\""
	exit 1
fi

CHSSectorMax=63

if ((	( ${bootfs_part_start} < ${CHSSectorMax} ) || \
	( ${bootfs_part_start} >= ${BootFsBlocksMax} ) || \
	( ${bootfs_part_sectors} <  ${BootFsBlocksMin} ) || \
	( ${bootfs_part_sectors} >= ${BootFsBlocksMax} ) \
   ))
then
	echo "${MyBase}: ERROR: May be broken image. SdFile=\"${SdFile}\""
	exit 1
fi

dd_skip=1
dd_bs=$(( ${bootfs_part_start} * 512 ))
dd_count=$(( ( ${bootfs_part_sectors} + ${bootfs_part_start} - 1 ) / ${bootfs_part_start} ))

echo "${MyBase}: INFO: Dump bootfs partition. if=\"${SdFile}\", of=\"${BootFsImg}\""
if ! qemu-img dd -f "${_DriveFormat}" "if=${SdFile}" "bs=${dd_bs}" "skip=${dd_skip}" "count=${dd_count}" "of=${BootFsImg}"
then
	echo "${MyBase}: ERROR: Can not extract bootfs partition. if=\"${SdFile}\" of=\"${BootFsImg}\""
	exit 1
fi

echo "${MyBase}: INFO: bootfs partition information. if=\"${SdFile}\""
if ! fatcat -i "${BootFsImg}"
then
	echo "${MyBase}: ERROR: May be broken FAT BPB. if=\"${SdFile}\""
	exit 1
fi

echo "${MyBase}: INFO: Extract /${Kernel8Img}."
if ! fatcat "${BootFsImg}" -r "/${Kernel8Img}"  > "${Kernel8Temp}"
then
	echo "${MyBase}: ERROR: Can not extract /${Kernel8Img}."
	exit 1
fi

echo "${MyBase}: INFO: Extract /${Initramfs8}."
if ! fatcat "${BootFsImg}" -r "/${Initramfs8}"  > "${Initrd8Temp}"
then
	echo "${MyBase}: ERROR: Can not extract /${Initramfs8}."
	exit 1
fi

# Get kernel version string
# arg PathToKernelFile
# echo kernel version string
# return ==0: Success
#        !=0: Failed
function KernelVersion() {
	zcat "$1" | strings | grep -i '^Linux[[:space:]]\+version' \
	| head -1 | gawk '{print $3}'
	return $?
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
	kernel_version_cur="$( KernelVersion "${KernelFile}" )"
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
	echo "${MyBase}: INFO: Backup kernel file \"${KernelFile}\" to \"${KernelFileBackup}\"."
	if ! cp -p "${KernelFile}" "${KernelFileBackup}"
	then
		echo "${MyBase}: ERROR: Can not backup \"${KernelFile}\" to \"${KernelFileBackup}\"."
		exit 1
	fi
fi

if [[ -e "${InitrdFile}" ]]
then
	echo "${MyBase}: INFO: Backup initrd file \"${InitrdFile}\" to \"${InitrdFileBackup}\"."
	if ! cp -p "${InitrdFile}" "${InitrdFileBackup}"
	then
		echo "${MyBase}: ERROR: Can not backup \"${InitrdFile}\" to \"${InitrdFileBackup}\"."
		exit 1
	fi
fi

echo "${MyBase}: INFO: Copy kernel file /bootfs/${Kernel8Img} to \"${KernelFile}\"."
if ! mv -f "${Kernel8Temp}" "${KernelFile}"
then
	echo "${MyBase}: ERROR: Can not copy kernel file /bootfs/${Kernel8Img} to \"${KernelFile}\"."
	exit 1
else
	echo "${MyBase}: INFO: Copy initrd file /bootfs/${Initramfs8} to \"${InitrdFile}\"."
	if ! mv -f "${Initrd8Temp}" "${InitrdFile}"
	then
		echo "${MyBase}: ERROR: Can not copy initrd file /bootfs/${Initramfs8} to \"${InitrdFile}\"."
		echo "${MyBase}: INFO: Revert kernel file \"${KernelFile}\"."
		if ! cp -p "${KernelFileBackup}" "${KernelFile}"
		then
			echo "${MyBase}: ERROR: Can not revert kernel file \"${KernelFile}\"."
		fi
		exit 1
	fi
fi
exit 0
