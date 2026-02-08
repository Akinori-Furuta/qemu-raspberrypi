# Run Raspberry Pi OS trixie 32bit on emulated Raspberry Pi 2 model B

## Introduction

Raspberry Pi OS Trixie 32bit runs on QEMU emulated
Raspberry Pi 2 model B. Now experimental release,
may be unstable and slower than [emulating 64bit OS](./readme.md).

To try running Raspberry Pi OS Trixie 32bit on QEMU,
follow procedures as follows.

## Create a Raspberry Pi OS 32bit image media

Create a Raspberry Pi OS 32bit image media by
Raspberry Pi imager with parameters as following table.

|Item|Choice or Example|Referred as|Note|
|----|----|----|----|
|Media capacity|8Gbytes or more||Initial rootfs uses 4.3Gibytes spaces|
|Pi device|Raspberry Pi 2||emulate model 2B on QEMU|
|Operating System|Raspbery Pi OS (32-bit)||Debian release 13 (trixie)|
|host name|rpi2b-trixie32|_PiHostName_|Network host name. To resolve network address by name, use _PiHostName_.local and bridge interface|
|Capital city|City of your location||Now matter what this selection, initial system locale (the LANG environment value) is fixed to en_GB.UTF-8|
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

## Run commands to emulate Raspberry Pi OS trixie 32bit

Clone git repository.

```bash
git clone https://github.com/Akinori-Furuta/qemu-raspberrypi.git
cd qemu-raspberrypi
# Checkout branch working with Trixie release.
git branch -t follow-trixie origin/follow-trixie
git checkout follow-trixie
```

Setup symbolic links to scripts.

```bash
./setup-rpi2-trixie-32.sh
```

> [!NOTE]
> It's similar to 64bit support version `./setup-rpi3-trixie-64.sh`

Attach a Raspberry Pi OS image media to PC.
Find Raspberry Pi OS image media path.

```bash
./rpi2image.sh find
# You may be requested your password to acquire root privilege.
[sudo] password for YourLoginId: 
```

> [!NOTE]
> The file node `./rpi2image.sh` links to
> `./downloads/host/rpi3image.sh`.
> It intentionally shares script with 64bit (Raspberry Pi
> model 3B) support script.

You will get the path to Raspberry Pi OS image media as follows,

```text
rpi2image.sh: INFO: Found Raspberry Pi OS image media at "/dev/sdb".
rpi2image.sh: INFO: DEV_PATH="/dev/sdb"
rpi2image.sh: INFO: /dev/sdh.VENDOR="Prolific Technology Inc."
rpi2image.sh: INFO: /dev/sdh.MODEL="SD Card Reader  "
rpi2image.sh: INFO: /dev/sdh.SIZE=7.50Gi/8.05G bytes
```

> The above example output says the path to media is /dev/sdb.

Convert the Raspberry Pi OS image media into an eMMC/SDCard
image file. Replace the block device node `/dev/sdX` with
the node which is attached Raspberry Pi OS image media.

```bash
./rpi2image.sh /dev/sdX
```

First step configuration.

```bash
./rpi2vm32-1st.sh
```

Wait until done configuration process.

> [!TIP]
> You will see `login:` prompt, but leave it. Do not login.

You will see reboot kernel log as follows,

```text
[  OK  ] Reached target reboot.target - System Reboot.
[  904.846648] reboot: Restarting system
[  905.856552] Reboot failed -- System halted
```

Type **[CTRL]-[a]** **[x]** to terminate the QEMU emulator.

Second step configuration.

```bash
./rpi2vm32-2nd.sh
```

Login to Raspberry Pi on the QEMU console/monitor terminal.

```text
Debian GNU/Linux 13 PiHostName ttyAMA0

My IP address is 10.0.2.15 fec0::30cb:bc27:a7a3:5e9a

PiHostName login: PiUserName
Password: PiUserPassword
```

Run the post setup and shutdwon on the QEMU console/monitor terminal.

```bash
sudo /var/local/post-setup.sh
sudo /sbin/init 0
```

> [!NOTE]
> post-setup.sh does following setups,
>
> * Disable ModemManager.service.
> * Disable rpi-eeprom-update.service.
> * Install power-off and reboot dkms driver bcm2835_power_off.

Now, ready to run the Raspberry Pi OS on the QEMU emulator.

```bash
./rpi2vm32.sh
```

Currently, the Raspberry Pi OS "trixie" 32bit graphical desktop runs on QEMU.

> [!NOTE]
> There are some restrictions on QEMU emulator.
>
> * Disable eMMC/SDCard I/O DMA transfer
>   * Use PIO transfer to prevent corrupting rootfs filesystem.
> * Disable watchdog timer.
> * Fix graphical screen resolution to 1024x768.
> * Disable rpi-eeprom-update.service

To exit the Raspberry Pi OS emulation,

|Command|qemu-system-aarch64 option|Action|kernel sequence|
|---|---|---|---|
|/sbin/init 0||Terminate|power off|
|/sbin/reboot|-no-reboot (rpi2vm32.sh default)|Terminate|reboot|
|/sbin/reboot|without -no-reboot|Reboot|reboot|

After updating kernel in emulated Raspberry Pi OS, exit the QEMU emulation and run following command on the host PC.

```bash
./rpi2vm32-upkernel.sh
```

`./rpi2vm32-upkernel.sh` updates bootfs/kernel7.img and bootfs/initramfs7 by following steps.

* Extract bootfs (/boot/firmware) partition from the SDCard/eMMC ($SDFile) image.
* Copy kernel7.img and initramfs7 files from the extracted
  partition to temporary files.
* Compare current kernel7.img and initramfs7 under host bootfs/
  directory with the temporary files extracted above.
  * If compared files are same to the temporary files,
    do nothing and exit.
* Backup current kernel7.img and initramfs7.
  * Copy the kernel7.img to kernel7-_$(uname -r)_.img.
  * Copy the initramfs7 to initramfs7-_$(uname -r)_.img.
  * The _$(uname -r)_ string is picked from current kernel7.img.
* Move the temporary files to kernel7.img and initramfs7.
  * If failed moving, try revert kernel7.img and initramfs7.
