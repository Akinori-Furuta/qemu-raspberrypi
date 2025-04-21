.PHONY: all

all: rpios32bit-host-kit.tar.gz rpios64bit-host-kit.tar.gz rpios32bit-target-kit.tar.gz

rpios32bit-host-kit.tar.gz: host/rpi3image.sh \
	host/rpi2vm32-1st.sh \
	host/rpi2vm32-2nd.sh \
	host/rpi2vm32-common.sh \
	host/rpi2vm32.sh \
	host/rpi2vm32.conf \
	host/rpi2vm32-vnc.sh \
	host/rpi2vm32-vnc.conf
	( cd host; tar -zcvf ../$@ $(notdir $^) ) || rm $@

rpios64bit-host-kit.tar.gz: host/rpi3image.sh \
	host/rpi3vm64-1st.sh \
	host/rpi3vm64-2nd.sh \
	host/rpi3vm64-common.sh \
	host/rpi3vm64.sh \
	host/rpi3vm64.conf \
	host/rpi3vm64-vnc.sh \
	host/rpi3vm64-vnc.conf
	( cd host; tar -zcvf ../$@ $(notdir $^) ) || rm $@

rpios32bit-target-kit.tar.gz: target/etc/systemd/system.conf \
	target/etc/systemd/system.conf.diff \
	target/etc/systemd/system/lightdm.service \
	target/etc/X11/xorg.conf.d/00-fbdev.conf \
	target/etc/X11/xorg.conf.d/01-screen.conf \
	target/var/local/post-setup.sh \
	target/var/local/raspi-config-qemu.sh
	tar -C target -zcvf rpios32bit-target-kit.tar.gz .

clean:
	rm -f rpios32bit-host-kit.tar.gz \
	      rpios64bit-host-kit.tar.gz \
	      rpios32bit-target-kit.tar.gz
