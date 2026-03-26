# rip3image.sh Command Line

## Synopsis

rpi3image.sh [-option [parameter]]... {find | /path/to/block-device}

## Description

`rpi3image.sh` converts a bootable meida created by
[Raspberry Pi imager](https://www.raspberrypi.com/software/)
into a eMMC/SDCard image file and some files to
start QEMU emulation. It modifies files
in image file, and extracts kernel, initramfs,
and device-tree blobs to run QEMU emulation.

`rpi3image.sh` requires `root` (super user) privilege.
With `root` privilege, it reads block devices, inserts
NBD(Network Block Device) module into kernel,
connects/disconnects a image file to NBD, fsck
partitons in image file, resizes rootfs partition in
image file, mounts/unmounts a NBD, and
reads/modifies/writes/creates `root` owned files in
image file.

Running this command with `find` parameter scans block
devices `/dev/sd*` and see it likes (they like) bootable
Raspberry Pi OS media. When `rpi3image.sh` command finds
a bootable media, it outputs message like as follows,

```text
rpi3image.sh: INFO: Found Raspberry Pi OS image media at "/dev/sdb".
rpi3image.sh: INFO: DEV_PATH="/dev/sdb"
rpi3image.sh: INFO: /dev/sdb.VENDOR="JMicron "
rpi3image.sh: INFO: /dev/sdb.MODEL="Generic         "
rpi3image.sh: INFO: /dev/sdb.SIZE=14.9Gi/16.0G bytes
```

The message above says that,

+ Found a media at block device path `/dev/sdb`
+ Device vendor is "JMicron"
+ Device Model is "Generic" (Generic USB storage device)
+ Size (Capacity) is 14.9Gibytes (in based 10,
  human-redable, 16Gbytes).

Running this command with a device path
`/path/to/block-device` (for most cases, path becomes
`/dev/sd`_X_ ,the _X_ is a one of a-z, aa-zz, ... ),
it converts bootable Raspberry Pi OS media
at `/dev/sd`_X_ into files those are eMMC/SDCard image,
kernel, initramfs, and device-tree blobs.

## Options

To change modification applied to output image file,
and device-tree files, add options to command line.
Option(s) change output path, image file format,
applying patches to files in image file,
and modifications to device-tree blobs.

### Conversion

Following list shows options to change conversion
results.

+ `-f`<br>
  Force conversion. If you want to overwrite files under
  `bootfs/` directory and output image file, use
  this option.
+ `-o path`<br>
  Specify a image file path or directory (path ended
  by `/`) to output.
  + If `path` is a file (or not path to a directory),
    converted image file `path` will be created. And copy
    files from bootfs partition to directory `bootfs/`
    under directory of `path`.
    The extension part of `path` could be one of `.img`,
    `.qcow`, or `.qcow2`. The extension part specifies
    file format as follows,
    + `.img`: Raw format.
    + `.qcow`: QCOW format.
    + `.qcow2`: QCOW2 format with compression. The
      QCOW2 format achieves high compression ratio
      just after creating a image file. But it may
      grow size near to raw format.
      The trim process at initial setup grows file size.
  + If `path` is a directory, converted image file will
    be stored into directory `path` . And copy files from
    bootfs partition to directory `path/bootfs`. The image
    file format is fixed to raw (`.img`) or
    QCOW2 (`.qcow2`). When using `-m` option, the image
    file format is fixed to QCOW2.
+ `-s number`<br>
  Specify image file size in `number` GiBytes.
  The `number` should be grater than bootable media size
  and match to 2^i (here, integer i >= 0).
  For example, the `number` will be one of 8, 16, 32, 64,...
  Without this option, image file size is the minimal
  number which satisfies larger than or equal to bootable
  media size and equal to 2^i (exist i).
+ `-m`<br>
  Specify migrate a bootable media used in real machine
  into a image file runs on QEMU emulator.
  More details in [Notes for Migrate Bootable Media Runs
  on Real Board to Virtual Machine - migrate.md](./migrate.md).
  This option changes following actions while converting
  a bootable media,
  + Do not check the number of partitions in
    bootable media.
  + Convert a bootable media into a qcow2 formatted
    image file.
  + Do not grow rootfs partition up to end of virtual
    drive.
  + Do not change file `firstrun.sh` copied from
    bootfs partition. It may have been removed
    from bootfs partition. But, it have been
    still remained, you remove it to avoid security
    risk. `firstrun.sh` contains hashed password
    string and WiFi key.
+ `-p patch_specs`<br>
  Options to patch files in created image file.
  `patch_specs` is a comma separated strings
  `spec[,spec]...`. You can specify `spec` as
  following list,
  + `dist_upgrade` or `dist-upgrade`<br>
  Prepare [`sudo apt dist-upgrade` from release
  `bookworm` to `trixie`](https://forums.raspberrypi.com/viewtopic.php?t=392376).
  With this option, following patches are applied
  to image file and device-tree,
    + Modify device tree to replace watchdog driver.
    + Add DKMS driver `bcm2835_power_off`, it
      attaches watchdog and power off blocks.

  So, you need to force exit emulator at 1st, and
  2nd boot `./rpi[23]vm{32|64}-{1st|2nd}.sh` by typing
  in QEMU escape sequence **[Ctrl]-[a] [x]**
  just after kernel reaches power off state.
  And install the DKMS driver in normal booted
  Raspberry Pi OS using
  `sudo /var/local/post-setup.sh`.

### Debug

The following list shows debugging options.

+ `-x debug_specs`<br>
  Options to debug script or created image.
  `debug_specs` is a comma separated strings
  `spec[,spec]...`. You can specify `spec` as
  following list,
  + `debug`<br>
    Outputs more debug messages.
  + `copy_only` or `copy-only`<br>
    Only copy image from bootable media.
    Do not modify files in image file.
    Using this option, the created image file may not
    boot or terminate during boot process.
