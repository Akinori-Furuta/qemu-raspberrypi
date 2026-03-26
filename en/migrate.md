# Notes for Migrate Bootable Media Runs on Real Board to Virtual Machine

## Introduction

Run [`rpi3image.sh`](../downloads/host/rpi3image.sh)
with `-m` option can convert a bootable media which
runs on real Raspberry Pi machines into image files.

You can run QEMU emulator with converted image files.

|OS bits|OS release|Link to steps|Setup script|Emulator machine|
|:-----:|----------|-------------|------------|:--------------:|
|32|bookworm|[Migrate steps 32bit OSes](#migrate-steps-32bit-oses)|setup-rpi2-bookworm-32.sh|2B|
|32|trixie|[Migrate steps 32bit OSes](#migrate-steps-32bit-oses)|setup-rpi2-trixie-32.sh|2B|
|64|bookworm|[Migrate steps 64bit OSes](#migrate-steps-64bit-oses)|setup-rpi3-bookworm-64.sh|3B|
|64|trixie|[Migrate steps 64bit OSes](#migrate-steps-64bit-oses)|setup-rpi3-trixie-64.sh|3B|

### Notes for 32bit OS Kernel and Userland

Raspberry Pi OSes 32bit are constructed from 32bit userland packages
and 32bit and 64bit kernel packages. When the Raspberry Pi OS 32bit
runs on real boards, they vary kernel bits 32bit or 64bit. Of course,
userland executables are 32bit binaries.

The following table shows Board model and kernel bits relations.

| Board Model | Kernel bits |
|-------------|:-----------:|
|Zero|32|
|Zero W|32|
|Zero WH|32|
|Zero 2W|32 or 64 (**note 1**)|
|1 model A|32|
|1 model A+|32|
|1 model B|32|
|1 model B+|32|
|2 model B v1.1|32|
|2 model B v1.2|32 or 64 (**note 1**)|
|3 model A+|32 or 64 (**note 1**)|
|3 model B|32 or 64 (**note 1**)|
|3 model B+|32 or 64 (**note 1**)|
|4 model B|32 or 64 (**note 1**)|
|5|64|
|400|32 or 64 (**note 1**)|
|500|64|
|Compute Module 1|32|
|Compute Module 3|32 or 64 (**note 1**)|
|Compute Module 3L|32? or 64 (**note 1**)|
|Compute Module 3+|32 or 64 (**note 1**)|
|Compute Module 4|32 or 64 (**note 1**)|
|Compute Module 4S|32 or 64 (**note 1**)|
|Compute Module 5|64|

> **(note 1)** When you set 0 to [`arm_64bit`](https://www.raspberrypi.com/documentation/computers/config_txt.html) in `config.txt`, the boot loader
> starts 32bit kernel image. 

The Processor architecture on a board supports 64bit instructions (i.e.
architecture is ARMv8-A or it's successors), the kernel runs in 64bit
mode. The otherwise, the kernel runs in 32bit mode.

After migrate a bootable media to the QEMU virtual machine Raspberry
Pi 2 model B, Raspberry Pi OSes 32bit runs kernel in 32bit mode.

The kernel runs in 32bit, the Raspberry Pi OS can supports DKMS kernel
drivers and kernel related builds.

## Migrate steps 32bit OSes

To migrate a Raspberry Pi OS 32bit media which runs on a real board
to a QEMU virtual machine, do following steps.

1. Shutdown real board and remove media from it.
2. Install required packages to host machine.
3. Clone Git Repository.
4. Setup scripts.
5. Attach the media which removed from real board.
6. Find device path to the attached media.
7. Convert the media into files to emulate.
8. Start emulator.
9. Login emulated Raspberry Pi OS.
10. Setup Raspberry Pi OS in emulated machine.

### Remove SD Card from Raspberry Pi (32bit)

Shutdown Raspberry Pi board. Use safe way to shutdown,
`sudo /sbin/shutdown now`, `sudo /sbin/init 0`,
or suitable command for your board.

```bash
sudo /sbin/shutdown now
```

Remove (Micro) SD Card from board.

### Preparation (32bit)

Do same steps in,

* [Install Required Packages - readme.md](../readme.md#install-required-packages)
* [Clone Git Repository - readme.md](../readme.md#clone-git-repository)

Commands in following steps are assumed typed in cloned git repository
directory `qemu-raspberrypi`.

### Convert a Bootable Media into Files (32bit)

Choose suitable setup script `setup-rpi2-trixie-32.sh`,
or `setup-rpi2-bookworm-32.sh`. And run.
See table at [Introduction](#introduction).

```bash
# If you will convert a Raspberry Pi OS Trixie (debian 13) release,
./setup-rpi2-trixie-32.sh
```

or

```bash
# If you will convert a Raspberry Pi OS Bookworm (debian 12) release,
./setup-rpi2-bookworm-32.sh
```

Attach the SD card removed from Raspberry Pi board to your PC.

Find your Raspberry Pi OS media from last `dmesg` log or scan
block devices.

```bash
sudo dmesg
-- snip --
[303825.765067] usb-storage 1-1.1:1.0: USB Mass Storage device detected
[303825.767916] scsi host0: usb-storage 1-1.1:1.0
[303826.816924] scsi 0:0:0:0: Direct-Access     Generic- USB3.0 CRW   -SD 1.00 PQ: 0 ANSI: 4
[303827.445252] usbcore: registered new interface driver uas
[303828.228336] scsi 0:0:0:1: Direct-Access     Generic- USB3.0 CRW   -SD 1.00 PQ: 0 ANSI: 4
[303828.238787] sd 0:0:0:0: [sda] 15728640 512-byte logical blocks: (8.05 GB/7.50 GiB)
[303828.239950] sd 0:0:0:0: [sda] Write Protect is off
[303828.240004] sd 0:0:0:0: [sda] Mode Sense: 2f 00 00 00
[303828.240840] sd 0:0:0:0: [sda] Write cache: disabled, read cache: enabled, doesn't support DPO or FUA
[303828.273244]  sda: sda1 sda2
[303828.274610] sd 0:0:0:0: [sda] Attached SCSI removable disk
-- snip --
```

> The log above says connected new storage device at `/dev/sda`.

Run `./rpi2image.sh` command with `-m` option and `find`,
`./rpi2image.sh` scans `/dev/sd*` and `/dev/mmcblk*`.

```bash
sudo ./rpi2image.sh -m find
-- snip --
rpi2image.sh: INFO: Found Raspberry Pi OS image media at "/dev/sda".
rpi2image.sh: INFO: DEV_PATH="/dev/sda"
rpi2image.sh: INFO: /dev/sda.VENDOR="Generic-"
rpi2image.sh: INFO: /dev/sda.MODEL="USB3.0 CRW   -SD"
rpi2image.sh: INFO: /dev/sda.SIZE=7.50Gi/8.05G bytes
-- snip --
```

> The log above says found a Raspberry Pi OS media at `/dev/sda`.

Convert a media on `/dev/sdX` (`X` will be
`{[a-z]|[aa-zz]|[aaa-zzz]|...}`, or `/dev/mmblkN`
`N` will be an integer number >= `0`). Here also add `-m` option.

```bash
sudo ./rpi2image.sh -m /dev/sdX
```

### Start Emulation Normally (32bit)

Start emulation using files from converted media.

```bash
./rpi2vm32.sh
```

It starts console/QEMU-monitor duplexed text terminal and GUI desktop.

### Disable Services and Install DKMS Power Off Driver (32bit)

Login emulated Raspberry Pi OS on console terminal,
_PiUserName_, and _PiUserPassword_ are same credential which
is used to login Raspberry Pi OS on real board.

```text
Raspbian GNU/Linux 13 PiHostName ttyAMA0

My IP address is Guest.IP.Address.OnLan xxxx:...:xxxx

PiHostName login: PiUserName
Password: PiUserPassword
```

Run setup command on emulated Raspberry Pi OS.

```bash
sudo /var/local/post-setup.sh
```

[`post-setup.sh`](../downloads/target/var/local/post-setup.sh)
does following changes.

+ Configure X window server to use simple frame buffer, if needed.
+ Disable services those aren't necessary on QEMU.
  + ModemManager
  + rpi-eeprom-update
+ Install power off DKMS driver, if needed.
  + Install packages to install DKMS modules.
  + Build the driver
  + Modprobe the drive

To terminate emulated Raspberry Pi OS, use usual shutdown command.
For example `/sbin/init 0`, `/sbin/shutdown`, or suitable command same
as used on real board.

```bash
sudo /sbin/init 0
```

## Update Kernel (32bit)

See [Update Kernel - readme-trixie32.md](../readme-trixie32.md).

## Migrate steps 64bit OSes

To migrate a Raspberry Pi OS 64bit media which runs on a real board
to a QEMU virtual machine, do following steps.

1. Shutdown real board and remove media from it.
2. Install required packages to host machine.
3. Clone Git Repository.
4. Setup scripts.
5. Attach the media which removed from real board.
6. Find device path to the attached media.
7. Convert the media into files to emulate.
8. Start emulator.
9. Login emulated Raspberry Pi OS.
10. Setup Raspberry Pi OS in emulated machine.

It's almost [same way to migrate 32bit OSes](#migrate-steps-32bit-oses).

### Remove SD Card from Raspberry Pi (64bit)

Shutdown Raspberry Pi board. Use safe way to shutdown,
`sudo /sbin/shutdown now`, `sudo /sbin/init 0`,
or suitable command for your board.

```bash
sudo /sbin/shutdown now
```

Remove (Micro) SD Card from board.

### Preparation (64bit)

Do same steps in,

* [Install Required Packages - readme.md](../readme.md#install-required-packages)
* [Clone Git Repository - readme.md](../readme.md#clone-git-repository)

Commands in following steps are assumed typed in cloned git repository
directory `qemu-raspberrypi`.

### Convert a Bootable Media into Files (64bit)

Choose suitable setup script `setup-rpi3-trixie-64.sh`,
or `setup-rpi3-bookworm-64.sh`. And run.

```bash
# If you will convert a Raspberry Pi OS Trixie (debian 13) release,
./setup-rpi3-trixie-64.sh
```

or

```bash
# If you will convert a Raspberry Pi OS Bookworm (debian 12) release,
./setup-rpi3-bookworm-64.sh
```

Attach the SD card removed from Raspberry Pi board to your PC.

Find your Raspberry Pi OS media from last `dmesg` log or scan
block devices.

```text
sudo dmesg
-- snip --
[303825.765067] usb-storage 1-1.1:1.0: USB Mass Storage device detected
[303825.767916] scsi host0: usb-storage 1-1.1:1.0
[303826.816924] scsi 0:0:0:0: Direct-Access     Generic- USB3.0 CRW   -SD 1.00 PQ: 0 ANSI: 4
[303827.445252] usbcore: registered new interface driver uas
[303828.228336] scsi 0:0:0:1: Direct-Access     Generic- USB3.0 CRW   -SD 1.00 PQ: 0 ANSI: 4
[303828.238787] sd 0:0:0:0: [sda] 15728640 512-byte logical blocks: (8.05 GB/7.50 GiB)
[303828.239950] sd 0:0:0:0: [sda] Write Protect is off
[303828.240004] sd 0:0:0:0: [sda] Mode Sense: 2f 00 00 00
[303828.240840] sd 0:0:0:0: [sda] Write cache: disabled, read cache: enabled, doesn't support DPO or FUA
[303828.273244]  sda: sda1 sda2
[303828.274610] sd 0:0:0:0: [sda] Attached SCSI removable disk
-- snip --
```

> The log above says connected new storage device at `/dev/sda`.

Run `./rpi3image.sh` command with `-m` option and `find`,
`./rpi3image.sh` scans `/dev/sd*` and `/dev/mmcblk*`.

```bash
sudo ./rpi3image.sh -m find
-- snip --
rpi3image.sh: INFO: Found Raspberry Pi OS image media at "/dev/sda".
rpi3image.sh: INFO: DEV_PATH="/dev/sda"
rpi3image.sh: INFO: /dev/sda.VENDOR="Generic-"
rpi3image.sh: INFO: /dev/sda.MODEL="USB3.0 CRW   -SD"
rpi3image.sh: INFO: /dev/sda.SIZE=7.50Gi/8.05G bytes
-- snip --
```

> The log above says found a Raspberry Pi OS media at `/dev/sda`.

Convert a media on `/dev/sdX` (`X` will be
`{[a-z]|[aa-zz]|[aaa-zzz]|...}`, or `/dev/mmblkN`
`N` will be an integer number >= `0`). Here also add `-m` option.

```bash
sudo ./rpi3image.sh -m /dev/sdX
```

### Start Emulation Normally (64bit)

Start emulation using files from converted media.

```bash
./rpi3vm64.sh
```

### Install DKMS Power Off Driver (64bit)

Login emulated Raspberry Pi OS on console terminal,
_PiUserName_, and _PiUserPassword_ are same credential which
is used to login Raspberry Pi OS on real board.

```text
Raspbian GNU/Linux 13 PiHostName ttyAMA0

My IP address is Guest.IP.Address.OnLan xxxx:...:xxxx

PiHostName login: PiUserName
Password: PiUserPassword
```

Run setup command on emulated Raspberry Pi OS.

```bash
sudo /var/local/post-setup.sh
```

> See ["Disable Services and Install DKMS Power Off Driver (32bit)"](#disable-services-and-install-dkms-power-off-driver-32bit) , to know what `post-setup.sh` does.

To terminate emulated Raspberry Pi OS, use usual shutdown command.
For example `/sbin/init 0`, `/sbin/shutdown`,
or suitable command same as used on real board.

```bash
sudo /sbin/init 0
```

## Update Kernel (64bit)

See [Update Kernel - readme.md](../readme.md).
