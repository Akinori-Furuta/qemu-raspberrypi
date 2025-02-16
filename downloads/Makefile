all: rpios32bit-target-kit.tar.gz rpios32bit-host-kit.tar.gz

rpios32bit-host-kit.tar.gz: host/*
	tar -C host -zcvf rpios32bit-host-kit.tar.gz .

rpios32bit-target-kit.tar.gz: target/etc/systemd/system.conf \
	target/etc/systemd/system.conf.diff \
	target/etc/systemd/system/lightdm.service \
	target/etc/X11/xorg.conf.d/* \
	target/var/local/*
	tar -C target -zcvf rpios32bit-target-kit.tar.gz .
