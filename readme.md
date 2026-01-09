# QEMU 上で RaspberryPi のイメージファイルを動かすまでにすること

## はじめに

Linux PC 上で QEMU を使って RaspberyPi のイメージを動かすことができるまでを目標に設定、知っておいた方が良いことをまとめていくリポジトリを作る予定です。

順次書き足していく予定です。構成の見直しでリンクが大幅に変わる可能性もあります。

## Follow Debian 13 (trixie) release Working in progress

Now working in progress on branch `follow-trixie`.
This branch contains scripts they run Raspberry Pi OS
Trixie 64bit on the QEMU emulating Raspberry Pi model 3B.
To try branch `follow-trixie`,

Install required packages.

```bash
sudo apt install git bridge-utils uml-utilities \
 qemu-system-common qemu-system qemu-system-arm qemu-utils \
 parted nbd-client cloud-guest-utils e2fsprogs virt-viewer \
 device-tree-compiler gawk
```

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
./setup-rpi3-trixie-64.sh
```

Attach Raspberry Pi OS image media to PC.
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
rpi3image.sh: INFO: /dev/sdb.VENDOR="JMicron "
rpi3image.sh: INFO: /dev/sdb.MODEL="Generic         "
rpi3image.sh: INFO: /dev/sdb.SIZE=14.9Gi/16.0G bytes
```

> The above example output says the path to media is /dev/sdb.

Convert Raspberry Pi OS image media into eMMC image file.

```bash
./rpi3image.sh /dev/sdX
```

First step configuration.

```bash
./rpi3vm64-1st.sh
```

Wait until done configuration process.

>[!tip]
> You will see "login: " prompt, but leave it. Do not login.

You will see reboot kernel log as follows,

```bash
[  OK  ] Reached target reboot.target - System Reboot.
[ 1175.220219] reboot: Restarting system
[ 1175.228158] Reboot failed -- System halted
```

Type **[CTRL]-[a]** **[x]** to terminate the QEMU emulator.

Second step configuration.

```bash
./rpi3vm64-2nd.sh
```

Login to Raspberry Pi on the QEMU console/monitor terminal.

```text
Debian GNU/Linux 13 raspberrypi-host ttyAMA1

My IP address is 10.0.2.15 fec0::30cb:bc27:a7a3:5e9a

PiHostName login: PiUserName
Password: PiUserPassword
```

Run the post setup and shutdwon on the QEMU console/monitor terminal.

```bash
sudo /var/local/post-setup.sh
sudo /sbin/init 0
```

>[!note]
> post-setup.sh does following setups,
>
> * Install power-off and reboot dkms driver bcm2835_power_off.
> * Disable ModemManager.service.
> * Disable rpi-eeprom-update.service.
>

Now, ready to run the Raspberry Pi OS on the QEMU emulator.

```bash
./rpi3vm64.sh
```

To exit the Raspberry Pi OS emulation,

|Command|qemu-system-aarch64 option|Action|kernel sequence|
|---|---|---|---|
|/sbin/init 0||Terminate|power off|
|/sbin/reboot|-no-reboot (rpi3vm64.sh default)|Terminate|reboot|
|/sbin/reboot|without -no-reboot|Reboot|reboot|

Currently, the Raspberry Pi OS "trixie" graphical desktop runs on QEMU.

![Running Raspberry Pi OS Debian 13 (trixie) release](img/run-raspberrypi-trixie-debian13-on-qemu-gui.png)

> [!note]
> There are some restrictions on QEMU emulator.
>
> * Disable watchdog timer.
> * Disable Bluetooth interface via serial port.
> * Disable Wifi device on SDIO bus.
>   * Also disable SDIO contoller which connected to
>     the WiFi device.
> * Fix graphical screen resolution to 1024x768.
> * Disable rpi-eeprom-update.service
> * Disable virtgpio driver
>

## 目次

* [Network Bridge を QEMU 向けに構成する](jp/bridge.md)
* [QEMU で実行する Rasiberry Pi イメージファイルをスクリプトを使って作る](jp/rpi-image-script.md)
  * [QEMU で実行する Rasiberry Pi イメージファイルを作る (お勧めしませんが手作業でする場合はこちらを参照して下さい)](jp/rpi-image.md)
* Raspberry Pi OS の初期設定を行う
  * [32bit OS の場合](jp/config-rpi.md)
  * [64bit OS の場合](jp/config-rpi-64.md)
* [apt upgrade をした後の対応](jp/follow-upgrade.md)

github 上で文書を書いていく練習も兼ねています。物足りなさや記述の稚拙さがあると思います。

![Raspberry pi OS 32bit on QEMU](img/raspberrypi-os-desktop.jpg)
