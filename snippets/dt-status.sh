#!/bin/bash

ProcDt=/proc/device-tree

cd "${ProcDt}"
find . -name '*' -type d |
while read
do
	DtNp="${REPLY}"
	DtStatus="${ProcDt}/${DtNp#./}/status"
	if [[ -e "${DtStatus}" ]]
	then
		echo "${DtStatus}=$(cat "${DtStatus}" | tr -d '\000' )"
	else
		echo "${DtStatus}=ENOENT"
	fi
done
