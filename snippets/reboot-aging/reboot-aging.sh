#!/bin/bash

MyWhich="$( which "$0" )"
MyPath="$( readlink -f "${MyWhich}" )"
MyDir="$( dirname "${MyPath}" )"
MyBase="${MyPath##*/}"
MyBody="${MyBase%.*}"
MyBodyNoSpace="$( echo -n ${MyBody} | tr -s '\000-\040' '_')"
MyBodyNoSuffix="${MyBody%%-*}"

StateFile="${MyDir}/${MyBody}.state"

if [[ -f "${StateFile}" ]]
then
	source "${StateFile}"
fi

if [[ -z "${RebootHoldSec}" ]]
then
	RebootHoldSec=1
fi

if [[ -z "${RebootStepSec}" ]]
then
	RebootStepSec=1
fi

if [[ -z "${RebootHoldSecMin}" ]]
then
	RebootHoldSecMin=1
fi


if [[ -z "${RebootHoldSecMax}" ]]
then
	RebootHoldSecMax=120
fi

do_nothing=""
kernel_params=( $(cat /proc/cmdline) )

for kp in ${kernel_params[*]}
do
	if [[ "${kp}" == reboot-aging=* ]]
	then
		kp_val="${kp##*=}"
		case "${kp_val}" in
		(0|no|off)
			do_nothing=yes
			break
			;;
		(*)
			# No reaction.
			;;
		esac
	fi
done

if [[ -n "${do_nothing}" ]]
then
	echo "${MyBase}: $( date +%y%m%d-%H%M%S-%s ): Exit due to kernel parameter reboot-aging=${kp_val}"
	exit 1
fi

next_hold_sec=$(( ${RebootHoldSec} + ${RebootStepSec} ))

if (( ${next_hold_sec} > ${RebootHoldSecMax} ))
then
	next_hold_sec=${RebootHoldSecMin}
fi

cat << EOF > "${StateFile}"
RebootHoldSec=${next_hold_sec}
RebootStepSec=${RebootStepSec}
RebootHoldSecMin=${RebootHoldSecMin}
RebootHoldSecMax=${RebootHoldSecMax}
EOF

echo "${MyBase}: $( date +%y%m%d-%H%M%S-%s ): Sleep ${next_hold_sec}"
sleep ${next_hold_sec}
echo "${MyBase}: $( date +%y%m%d-%H%M%S-%s ): Reboot"
/sbin/reboot
