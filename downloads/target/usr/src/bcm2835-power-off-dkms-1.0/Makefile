# SPDX-License-Identifier: GPL-2.0+
# Make BCM2835 simple power off driver used on QEMU emulator.
# Copyright(c) 2025 Akinori Furuta <afuruta@m7.dionb.ne.jp>

# note: how to invoke from dkms
# MAKE[#num]="make kernelver=$kernelver kernel_source_dir=$kernel_source_dir"

ifeq ($(kernelver),)
# Invoked from command line
KVER ?= $(shell uname -r)
else
# Invoked from dkms
KVER ?= $(kernelver)
endif

ifeq ($(kernel_source_dir),)
# Invoked from command line
KERNELDIR ?= /lib/modules/$(KVER)/build
else
# Invoked from dkms
KERNELDIR ?= $(kernel_source_dir)
endif

CFLAGS += -Wall

# note: At first invocation obj-m is ignored.
#       At second invocation from kbuild, obj-m is
#       source file(s) list to build .ko.

obj-m := bcm2835_power_off.o

.PHONY: modules clean install

modules:
	$(MAKE) -C $(KERNELDIR) M=$$PWD KVER=$(KVER) modules

clean:
	$(MAKE) -C $(KERNELDIR) M=$$PWD KVER=$(KVER) clean

# Install to /lib/modules/$(KVER)/updates
install:
	$(MAKE) -C $(KERNELDIR) M=$$PWD KVER=$(KVER) modules_install
	depmod
