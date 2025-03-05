#!/bin/bash

# See https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/configuration/raspi-config.adoc
#  get more details.

# Graphical login, multi user.
echo "Configure 1/S5/B3 Desktop: Desktop GUI, requiring user to login."
sudo raspi-config nonint do_boot_behaviour B3

# Do not blank screen.
#  Note: 0: enable, 1: disable
echo "Configure 1/S5/D2 Screen Blanking: Disable screen blanking."
sudo raspi-config nonint do_blanking 1

# Use X11 display server.
echo "Configure 6/A6/W1 X11: Openbox window manager with X11 backend".
sudo raspi-config nonint do_wayland W1

# Enable VNC service.
#  Note: 0: enable, 1: disable
echo "Configure 3/I3 VNC: Enable graphical remote desktop access."
sudo raspi-config nonint do_vnc 0
