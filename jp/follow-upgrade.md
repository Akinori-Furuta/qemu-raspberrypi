# apt upgrade をした後の対応

仮想マシンで動かしている Raspberry Pi OS で sudo apt update; sudo apt upgrade をすると kernel または initramfs が更新される場合があります。追従するには更新されたファイルをホストマシンへコピーします。kernel, initramfs が更新されたかどうか、簡単に見るには次の様な方法があります。以下、各項目は仮想 Raspberry Pi マシン内の操作です。

+ /boot/firmware 以下に配置されたファイルのタイムスタンプが更新されている。
+ `sudo apt upgrade` で linux-image-\*, または initramfs-\* package がインストールされた。
  + /var/log/apt/history.log またはそのアーカイブファイルの記録を読むと後からでも確認できます。
+ `uname -a` で表示される kernel version に比べて `ls -la /lib/modules` で表示されてるディレクトリ群の version に新しい(値が大きい)ものがある。

kernel 更新に追従するには、仮想 Raspberry Pi マシンを動作させ、ホストマシン上で次の操作を行い、仮想マシンのファイル群をホストマシンへコピーして下さい。

```bash
# Change directory to containing SD card image file and bootfs/* files.
cd /PathTo/RpiVMFiles
# Copy files from QEMU-VirtualMacnhie:/boot/firmware to HostMachine:./bootfs 
#  It may take 10 minutes. Very slow copy.
rsync -av PiUserName@PiHostName.local:/boot/firmware/ ./bootfs
```

> [!TIP]
> bluez-firmware, firmware-\*, raspi-firmware, rpi-update package が更新された場合も kernel, initramfs が更新される可能性があります。仮想マシンなので firmware 更新による変化は無いと考えられ、追従しなくても特段の問題は無いでしょう。
