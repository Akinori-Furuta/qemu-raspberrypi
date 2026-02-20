#!/bin/bash

grep '[[:space:]]*phandle' \
	| sed 's/^.*<\(.*\)>.*$/\1/' \
	| gawk -n 'BEGIN {max=0;}
{phval=$1 + 0; if (max < phval) {max=phval;};}
END {printf "0x%x\n", max;}'
