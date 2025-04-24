# QEMU 上で RaspberryPi のイメージファイルを動かすまでにすること

## はじめに

Linux PC 上で QEMU を使って RaspberyPi のイメージを動かすことができるまでを目標に設定、知っておいた方が良いことをまとめていくリポジトリを作る予定です。

順次書き足していく予定です。構成の見直しでリンクが大幅に変わる可能性もあります。

## 目次

+ [Network Bridge を QEMU 向けに構成する](jp/bridge.md)
+ [QEMU で実行する Rasiberry Pi イメージファイルをスクリプトを使って作る](jp/rpi-image-script.md)
  + [QEMU で実行する Rasiberry Pi イメージファイルを作る (お勧めしませんが手作業でする場合はこちらを参照して下さい)](jp/rpi-image.md)
+ Raspberry Pi OS の初期設定を行う
  + [32bit OS の場合](jp/config-rpi.md)
  + [64bit OS の場合](jp/config-rpi-64.md)
+ [apt upgrade をした後の対応](jp/follow-upgrade.md)

github 上で文書を書いていく練習も兼ねています。物足りなさや記述の稚拙さがあると思います。

![Raspberry pi OS 32bit on QEMU](img/raspberrypi-os-desktop.jpg)
