# rpi3vm64.conf Configuration File

## Introduction

The scripts [`rpi3vm64.conf`](../downloads/host/rpi3vm64.conf) and
[`rpi3vm64-vnc.conf`](../downloads/host/rpi3vm64-vnc.conf) load
multi layered configuration file(s). These configuration files
contain variables to specify options to QEMU emulator.
These variables are written in bash sell style syntax.

## Loading Order

Configuration files are loaded multi layered order. In short,
Invoking script by command strings `rpi3vm64-l1-l2-l3.conf`,
the script loads configuration files `rpi3vm64.conf`,
`rpi3vm64-l1.conf`, `rpi3vm64-l1-l2.conf`, and `rpi3vm64-l1-l2-l3.conf`
in order. Variables in configuration files could be overwritten
in file which is loaded later.

The path to configuration files(s) are delivered from command line
argument 0 ($0, command strings), and real path to script. For example,
there is a symbolic link node `./rpi3vm64-svga-nat.sh` in the current
directory `/home/user/qemu-raspberrypi` linking to
`./downloads/host/rpi3vm64.sh`, and invoke `./rpi3vm64-svga-nat.sh`.

```text
$ pwd
/home/user/qemu-raspberrypi
$ ls -o -g rpi3vm64-svga-nat.sh
lrwxrwxrwx 1 26 Mar  6 11:22 rpi3vm64-svga-nat.sh -> downloads/host/rpi3vm64.sh
$ ./rpi3vm64-svga-nat.sh
```

The "argument 0" and "real path to script" becomes as follows,

* argument 0 (= _Arg0_):
   `./rpi3vm64-svga-nat.sh`
  * directory argument 0 (= _DirArg0_):
   `./`
  * base argument 0 (= _BaseArg0_):
   `rpi3vm64-svga-nat.sh`
  * body argument 0 (= _BodyArg0_):
   `rpi3vm64-svga-nat`
* real path to script (= _ScriptPath_):
   `/home/user/qemu-raspberrypi/downloads/host/rpi3vm64.sh`
  * directory real path to script (= _ScriptDir_):
   `/home/user/qemu-raspberrypi/downloads/host`

Here are more details delivered strings represented by bash expressions.

* _Arg0_: The argument 0 `${0}`
  * _DirArg0_: `$( dirname "${Arg0}" )`
  * _BaseArg0_: `$( basename "${Arg0}" )`
  * _BodyArg0_: `${BaseArg0%.*}`
* _ScriptPath_: `$( readlink -f "$( which "${0}" )" )`
  * _ScriptDir_: `$( dirname "${ScriptPath}" )`

Configuration file(s) are searched and included (sourced) following order,

1. `${ScriptDir}/rpi3vm64.conf`
2. `${DirArg0}/rpi3vm64.conf`
3. `${ScriptDir}/rpi3vm64-svga.conf`
4. `${DirArg0}/rpi3vm64-svga.conf`
5. `${ScriptDir}/rpi3vm64-svga-nat.conf`
6. `${DirArg0}/rpi3vm64-svga-nat.conf`

> [!NOTE]
> If the path at order (2M - 1) and (2M)
> (M is element of _NaturalNumber_) are same file
> (ex. `${ScriptDir}/rpi3vm64.conf` and `${DirArg0}/rpi3vm64.conf`
> are same file), include file at order (2M).

Call recursive function with argument `$BodyArg0`, the function
truncates trailing "`-*`" from the argument it will be new argument.
The function call self recursively until no more trailing "`-*`",
construct configuration file path from argument prefixed `$ScriptDir`
and `$DirArg0`, postfixed "`.conf`", include configuration file just
before recursive call returns.

## Variables

The configuration files
[`rpi3vm64.conf`](../downloads/host/rpi3vm64.conf) and
[`rpi3vm64-vnc.conf`](../downloads/host/rpi3vm64-vnc.conf) contain
parameters to feed options to `qemu-system-aarch64` command. These
parameters have suitable default value or automatically configured.
If you wish to configure more detail or change default script
behaviors, change values in .conf file.

* `ParameterName` _List format example_
  * **default:** _Default value_
  * **related option(s):** _Related QEMU option_
  * **Warning:**_This item shows warnings with this parameter._
  * **description:** _Parameter descriptions_
* `KernelFile`
  * **default:** `bootfs/kernel8.img`
  * **related option(s):** -kernel
  * **description:** Specify a kernel image file.
* `InitrdFile`
  * **default:** `bootfs/initramfs8`
  * **related option(s):** `-initrd`
  * **description:** Specify an initramfs file.
* `DtbFile`
  * **default:** `bootfs/bcm2710-rpi-3-b-qemu.dtb`
  * **related option(s):** `-dtb`
  * **description:** Specify a Device Tree blob file.
* `SdFile`
  * **default:** find a file from `*.img`, `*.qcow`, `*.qcow2`,
    see description.
  * **related option(s):** `-drive file=`
  * **description:** Specify an eMMC image file.
      If the variable `SdFile` isn't set (or is set to zero
      length string), find it from current directory.
      Find a file matches to `\*.img`, `\*.qcow`, `\*.qcow2` except matches to `swap\*`(cases are ignored). 
      The `format=` sub option of the`-drive` will be automatically
      detected. If many file are matched to image file,
      choose a first one from the files sorted alphabetical order.
* `Append`
  * **default:** `console=ttyAMA1,115200 console=tty1\
 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait\
 dwc_otg.fiq_fsm_enable=0\
 bcm2708_fb.fbwidth=1024 bcm2708_fb.fbheight=768\
 `
  * **related option(s):** `-append`
  * **description:** Kernel parameter strings. There are some
  notes for default value.
    * `dwc_otg.fiq_fsm_enable=0`: Currently this kernel module
    option is obsoleted. No affects to DWC2 controller. Leave
    compatible with old Raspberry Pi Linux kernel.
    * `bcm2708_fb.fbwidth=1024 bcm2708_fb.fbheight=768`:
    Fix frame buffer pixels to 1024x768. If you want to
    change frame buffer pixels, change `fbwidth`, and `fbheight`
    value. The `bcm2708_fb` driver allocates frame buffer
    sized (`fbwidth` * `fbheight` * 4) bytes from
    CMA "Contiguous Memory Allocator" area. The CMA is
    configured by device-tree `linux,cma` node. It's
    default size is 64Mibytes.
* `NicBridge`
  * **default:** pickup one from bridge interface(s)
  * **related option(s):** `-netdev br=`
  * **description:** Specify a network bride interface name.
    If the variable `NicBridge` isn't set (or is set to zero
    length string), automatically choose one from network bridge
    interface(s).
    If there is no bridge interface, fall back to user mode (NAT)
    networking. So, you may also specify `NetDevOption` to
    map ports (NAT table).
* `NetDevHelper`
  * **default:** `/usr/lib/qemu/qemu-bridge-helper-suid` or
                 `/usr/lib/qemu/qemu-bridge-helper`
  * **related option(s):** `-netdev tap,helper=`
  * **description:** Executable path to configure TAP
    (bridge interface). Automatically find from
    `/usr/lib/qemu/qemu-bridge-helper-suid` or
    `/usr/lib/qemu/qemu-bridge-helper` which is suitable
    to use. To prepare `/usr/lib/qemu/qemu-bridge-helper-suid`,
    see [Configure Network Bridge for QEMU](./bridge.md).
* `NetDevOption`
  * **default:** See description
  * **related option(s):** `-netdev`
  * **description:** Specify parameter to `-netdev`. You may
    want to configure this value when you wish to use NAT
    networking with port mapping. To configure map guest
    ssh port to host port 10022 at NAT mode, use "`user,id=net0,hostfwd=tcp::10022-:22`". Here, `id=net0` is fixed.
    The virtual USB-ether networking device uses `netdev=net0`,
    so must assign each other via `net0`.
* `NicMac`
  * **default:** _read from a file or generated_
  * **related option(s):** `-device usb-net,mac=`
  * **description:** Specify a MAC address of virtual USB-Ethernet
    converter connected to virtual Raspberry Pi.
    If the variable `NicMac` isn't set (or is set to zero length
    string), read from file `${NicMacFile}` or automatically generated with prefix `${NicMacPrefix}`.
* `NicMacFile`
  * **default:** `net0_mac.txt`
  * **related option(s):** `-netdev usb-net,mac=`
  * **description:** Specify a file which (will) contains MAC
    address of virtual USB-Ethernet converter.
    If specified file isn't present, `rpi3vm64-vnc.sh` will
    create it which contains MAC address prefixed
    `${NicMacPrefix}`.
* `NicMacPrefix`
  * **default:** `b8:27:eb`
  * **related option(s):** `-netdev usb-net,mac=`
  * **description:** Specify a MAC address prefix of first
    three octets. The octets b8:27:eb is reserved for the
    Raspberry Pi devices.
* `DisplayOutput`
  * **default:** `spice-app`
  * **related option(s):** `-display`
  * **description:** Specify a protocol to access virtual machine
    screen. Choose one from `spice-app` or `gtk`.
    * `spice-app`: Use remote-viewer application.
    * `gtk`: Use window with control menus.
  * Note: The protocol `sdl` isn't supported. You may see
    black screen when choosing `sdl`.
* `VncDisplay`
  * **default:** `unix:/` or _blank_
  * **related option(s):** `-vnc`
  * **Warning:** Opening/creating a VNC connection port/node
    may cause some security risk. Any other people can connect
    to port/socket. So you should disable auto-login to
    desktop and console. To configure auto-login, use
    [`raspi-config`](https://www.raspberrypi.com/documentation/computers/configuration.html) command.
  * **description:** This variable is only available with
  script `downloads/host/rpi3vm64-vnc.sh`. Specify a socket
  interface to accept VNC connection from a client. Choose
  one from following specifier,
    * `unix:/` or _blank_: Wait VNC connection on a UNIX domain
      (node on file system) socket. Create a socket node at
      "$( dirname "\$0" )/\${0%.*}.sock". here, _$0_ is the
      argument 0 (executable name at command line). For example,
      * Invoke `rpi3vm64-vnc.sh` by absolute path
        `/home/user/git/qemu-raspberrypi/downloads/host/rpi3vm64-vnc.sh`,
        the socket node will be created at `/home/user/git/qemu-raspberrypi/downloads/host/rpi3vm64-vnc.sock`.
      * Invoke `rpi3vm64-vnc.sh` by via symbolic link
        `./rpi3vm64-vnc.sh -> /home/user/git/qemu-raspberrypi/downloads/host/rpi3vm64-vnc.sh` (link from node at current
        directory to the script file),
        the socket node will be created at `./rpi3vm64-vnc.sock`
        (current directory).
    * `unix:/path/to/socket`: Wait VNC connection on a UNIX
       domain (node on file system) socket. Create a socket node
       at "_/path/to/socket_".
    * `":*"`: Wait VNC connection on TCP port, the port number is
      automatically chosen from 5910 to 5999 which is not in use.
      VNC display number will be one of :10 to :99.
    * `":display_number"`: Wait VNC connection on TCP port
      _display_number_+5900 (display :_display_number_).
      For example specify "`:10`", then waits VNC connection
      at port `5910`.
      automatically chosen from 5910 to 5999 which is not in use.
      VNC display number will be one of :10 to :99.
    * `"interface_address:display_number"`: Wait VNC connection
      on TCP address:port _interface_address_:_display_number_+5900
      (display _interface_address_:_display_number).
      For example specify "`localhost:10`", then waits VNC
      connection at localhost(lo) port `5910`.
