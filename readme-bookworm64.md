# Run Raspberry Pi OS Bookworm 64bit on emulated Raspberry Pi 3 model B

## Introduction

Raspberry Pi OS Bookworm (Debian 12 / Legacy) 64bit runs
on QEMU emulated Raspberry Pi 3 model B.
It's experimentally supported.
You may see some "timeout" and "network connection lost".

To try running Raspberry Pi OS Bookworm 64bit on QEMU,
follow steps as bellow.

## Create a Raspberry Pi OS Bookworm 64bit Image Media

Create a Raspberry Pi OS 32bit image media by
the [Raspberry Pi imager](https://www.raspberrypi.com/software/)
with parameters as following table.

|Item|Choice or Example|Referred as|Note|
|----|----|----|----|
|Media capacity|8Gbytes or more||Initial rootfs uses 4.4Gibytes spaces|
|Pi device|Raspberry Pi 3||emulate model 3B on QEMU|
|Operating System|Raspbery Pi OS (Legacy, 64-bit)||Debian release 12 (Bookworm)|
|host name|rpi3b-bookworm64|_PiHostName_|Network host name. To resolve network address by name, use _PiHostName_.local and bridge interface|
|Capital city|City of your location||No matter what this selection, initial system locale (the LANG environment value) is fixed to en_GB.UTF-8|
|Time zone|Time zone to use||Automatically selected by "Capital city"|
|Keyboard layout|Same as host keyboard|||
|Username|pi|_PiUserName_||
|Password|raspberry|_PiUserPassword_||
|(WiFi) SSID|leave blank|||
|(WiFi) Password|leave blank|||
|Enable SSH|On|||
|Authentication mechanism|Use password authentication|||
|Enable Raspberry Pi Connect|Off|||

## Install required packages

Install packages to run scripts.

```bash
sudo apt install git bridge-utils uml-utilities \
 qemu-system-common qemu-system qemu-system-arm qemu-utils \
 qemu-system-modules-spice \
 parted nbd-client cloud-guest-utils e2fsprogs virt-viewer \
 device-tree-compiler gawk fatcat gzip binutils diffutils
```

## Clone Git Repository

Clone git repository.

```bash
git clone https://github.com/Akinori-Furuta/qemu-raspberrypi.git
cd qemu-raspberrypi
```

Setup symbolic links to scripts.

```bash
./setup-rpi3-bookworm-64.sh

```

## Copy Image From Bootable Media

Attach a Raspberry Pi OS image media to PC.
Find Raspberry Pi OS image media path.

```bash
./rpi3image.sh find
# You may be requested your password to acquire root privilege.
[sudo] password for YourLoginId: 
```

You will get the path to Raspberry Pi OS image media as follows,

```text
rpi3image.sh: INFO: Found Raspberry Pi OS image media at "/dev/sdb".
rpi3image.sh: INFO: DEV_PATH="/dev/sdb"
rpi3image.sh: INFO: /dev/sdh.VENDOR="Prolific Technology Inc."
rpi3image.sh: INFO: /dev/sdh.MODEL="SD Card Reader  "
rpi3image.sh: INFO: /dev/sdh.SIZE=7.50Gi/8.05G bytes
```

> The above example output says the path to media is /dev/sdb.

Convert the Raspberry Pi OS image media into an eMMC/SDCard
image file. Replace the block device node `/dev/sdX` with
the node which is attached Raspberry Pi OS image media.

```bash
./rpi3image.sh /dev/sdX
```

## Initial Setup Raspberry Pi OS

### First Step

First step configuration.

```bash
./rpi3vm64-1st.sh
```

Wait until done configuration process.

> [!TIP]
> You will see `login:` prompt, or shell prompt
> _PiUserName_`@raspberrypi:~ $`, but leave it.
> Do not login and command to shell prompt.

### Second Step

Second step configuration.

```bash
./rpi3vm64-2nd.sh
```

Wait until done configuration process.

## Run Normally

Now, ready to run the Raspberry Pi OS on the QEMU emulator.

```bash
./rpi3vm64.sh
```
You will see **Update Notification** Dialog box on
emulator screen window. Click **[Keep X]** button.

![Click \[Keep X\] - Update Notification](./img/keep-x-caped.png)

> [!NOTE]
> Once clicked the **[Keep X]** button, you will not see it again.

Currently, the Raspberry Pi OS Bookworm 64bit graphical desktop
runs on QEMU.

> [!NOTE]
> There are some restrictions on QEMU emulator.
>
> * Disabled eMMC/SDCard I/O DMA transfer
>   * Use PIO transfer to prevent corrupting rootfs filesystem.
> * Disabled services
>   * rpi-eeprom-update, ModemManager, and hciuart
> * Fixed graphical screen resolution to 1024x768.

## Exit Emulation

To exit the Raspberry Pi OS emulation, see
["Exit Emulation" in readme.md](./readme.md#exit-emulation).

## After Updating Kernel

After updating kernel in emulated Raspberry Pi OS,
exit the QEMU emulation and run following command on the host PC.

```bash
./rpi3vm64-upkernel.sh
```

To see what [`rpi3vm64-upkernel.sh`](./downloads/host/rpi3vm64-upkernel.sh) does, read [After Updating Kernel in readme.md](./readme.md#after-updating-kernel).
