#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause

MyId=$( /usr/bin/id -u )
MyBaseName="$( /usr/bin/basename "$0" )"
MyShortName="$( /usr/bin/echo -n "${MyBaseName%.*}" | /usr/bin/tr '\000-\040' '_' )"

MyTemp=""
Fb0="/dev/fb0"
Fb0Strip=64
Fb0Shot1st=""
Fb0ShotWatch=""
Fb0CutCols="1-16,19-28,31-40,43-52"

# At exit procedure
# args none
# echo don't care
# return don't care
function ExitProc() {
	if [[ -n "${MyTemp}" ]] && [[ -d "${MyTemp}" ]]
	then
		/usr/bin/rm -rf "${MyTemp}"
	fi
}

trap ExitProc EXIT

for temp in "/run/user/${MyId}" "/dev/shm" "/tmp"
do
	if [[ ! -d "${temp}" ]]
	then
		continue
	fi

	if MyTemp="$( /usr/bin/mktemp -d -p "${temp}" "${MyShortName}-$$-XXXXXXXXXX" )"
	then
		break
	fi
done

if [[ -z "${MyTemp}" ]]
then
	echo "${MyBaseName}: ERROR: Can not create temporary directory."
	exit 1
fi

/usr/bin/chmod 700 "${MyTemp}"

echo "${MyBaseName}: INFO: Created temporary directory \"${MyTemp}\"."

Fb0Shot1st="${MyTemp}/fb0-shot-1st.dmp"
Fb0ShotWatch="${MyTemp}/fb0-shot-watch.dmp"

echo "${MyBaseName}: INFO: Dump frame buffer image \"${Fb0Shot1st}\"."

function DumpFb32() {
	/usr/bin/sudo /usr/bin/dd "if=$1" "bs=${Fb0Strip}" count=1 2>/dev/null |
	/usr/bin/od -t x1 -A x |
	/usr/bin/cut -c "${Fb0CutCols}"
	return $?
}

if ! DumpFb32 "${Fb0}" > "${Fb0Shot1st}"
then
	echo "${MyBaseName}: ERROR: Can not read "${Fb0}"."
	exit 1
fi

# See https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/configuration/raspi-config.adoc
#  get more details.

# Graphical login, multi user.
echo "${MyBaseName}: INFO: Configure 1/S5/B3 Desktop: Desktop GUI, requiring user to login."
/usr/bin/sudo /usr/bin/raspi-config nonint do_boot_behaviour B3

# Do not blank screen.
#  Note: 0: enable, 1: disable
echo "${MyBaseName}: INFO: Configure 1/S5/D2 Screen Blanking: Disable screen blanking."
/usr/bin/sudo /usr/bin/raspi-config nonint do_blanking 1

# Use X11 display server.
echo "${MyBaseName}: INFO: Configure 6/A6/W1 X11: Openbox window manager with X11 backend."
/usr/bin/sudo /usr/bin/raspi-config nonint do_wayland W1

# Wait greeter or GUI session becomes ready.

TimeOut=180

function IsReadyGUISession() {
	/usr/bin/ps uwwh -C openbox -C lxsession -C lxpanel > /dev/null
	return $?
}

function IsReadyGUIGreeter() {
	/usr/bin/ps uwwh -C pi-greeter > /dev/null
	return $?
}

function CmpFb0() {
	local	result

	if ! DumpFb32 "${Fb0}" > "${Fb0ShotWatch}"
	then
		return 1
	fi

	cmp -s "${Fb0Shot1st}" "${Fb0ShotWatch}"
	return $?
}

wait_count=0
pi_greeter=""

while (( ${wait_count} < ${TimeOut} ))
do
	# Check running greeter, Window Manager,
	# Session Manager, or Menu panels
	if IsReadyGUISession
	then
		echo "${MyBaseName}: INFO: Running GUI session. wait_count=${wait_count}"
		pi_greeter="gui"
		break
	fi

	if IsReadyGUIGreeter
	then
		if [[ -z "${pi_greeter}" ]]
		then
			echo "${MyBaseName}: INFO: Starting GUI Greeter. wait_count=${wait_count}"
		fi
		pi_greeter="exec"

		if ! CmpFb0
		then
			echo "${MyBaseName}: INFO: Show GUI Greeter. wait_count=${wait_count}"
			pi_greeter="show"
			break
		fi
	fi

	if (( ( ${wait_count} % 10 ) == 0 ))
	then
		echo "${MyBaseName}: INFO: Waiting pi-greeter (Login GUI) becomes ready... wait_count=${wait_count}"
	fi
	/usr/bin/sleep 1
	wait_count=$(( ${wait_count} + 1 ))
done

if [[ -z "${pi_greeter}" ]]
then
	echo "${MyBaseName}: ERROR: Not ready pi-greeter (Login GUI)."
	exit 1
fi

echo "${MyBaseName}: INFO: Do additional sleep."
/usr/bin/sleep 4

# Enable VNC service.
#  Note: 0: enable, 1: disable
echo "${MyBaseName}: INFO: Configure 3/I3 VNC: Enable graphical remote desktop access."
/usr/bin/sudo /usr/bin/raspi-config nonint do_vnc 0

function ServiceActive() {
	/usr/bin/systemctl --no-pager -l status "${1}" |
	/usr/bin/grep  '^[[:space:]]*[aA]ctive:' |
	/usr/bin/sed 's/^[[:space:]]*[[:alnum:]]*:[[:space:]]*//' |
	/usr/bin/awk '{print $1}'
}

echo "${MyBaseName}: INFO: Waiting VNC server service ready."

wait_count=0
while (( ${wait_count} < ${TimeOut} ))
do
	vnc_state="$( ServiceActive "vncserver-x11-serviced.service" )"
	if [[ "${vnc_state}" == "active" ]]
	then
		echo "${MyBaseName}: INFO: VNC server service ready."
		break
	fi
	if (( ( ${wait_count} % 10 ) == 0 ))
	then
		echo "${MyBaseName}: INFO: Waiting VNC server service becomes ready... wait_count=${wait_count}"
	fi
	/usr/bin/sleep 1
	wait_count=$(( ${wait_count} + 1 ))
done

echo "${MyBaseName}: INFO: Done."
exit 0
