#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause

# Remove first run script, it contains password and pass phrase.
rm -f /boot/firmware/firstrun.sh
# Lock user rpi-first-boot-wizard
sudo usermod -L rpi-first-boot-wizard
# Disable services, they don't work well on emulator.
sudo systemctl disable hciuart.service
sudo systemctl disable ModemManager.service
sudo systemctl disable rpi-eeprom-update.service
