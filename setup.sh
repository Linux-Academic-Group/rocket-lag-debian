#!/bin/bash

IMAGES_DIR=images
DISK_IMAGE=$IMAGES_DIR/storage.img
DEBIAN_ISO=$IMAGES_DIR/debian-11.4.0-amd64.iso
DEBIAN_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-11.4.0-amd64-DVD-1.iso
DEBIAN_DIR=$IMAGES_DIR/debian
LAG_ISO=rocket-lag-debian.iso

setup_debian() {
    mkdir -p $DEBIAN_DIR
    if [ ! -f $DEBIAN_DIR ]; then
        # Download debian image if not present
        if [ ! -f $DEBIAN_ISO ]; then
            echo "No debian iso, downloading..."
            wget -q -O $DEBIAN_ISO $DEBIAN_URL
        fi
        bsdtar -C $DEBIAN_DIR -xf $DEBIAN_ISO
    fi
}

add_files() {
    chmod +w -R $DEBIAN_DIR/install.amd
    gunzip $DEBIAN_DIR/install.amd/initrd.gz
    find conf preseed.cfg | cpio -H newc -o -A -F $DEBIAN_DIR/install.amd/initrd
    gzip $DEBIAN_DIR/install.amd/initrd
    chmod -w -R $DEBIAN_DIR/install.amd/
}

build_image() {
    chmod +w $DEBIAN_DIR/isolinux/isolinux.bin
    cd $DEBIAN_DIR
    genisoimage -r -J -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot \
		-e boot/grub/efi.img \
		-no-emul-boot \
		-o ../$LAG_ISO .
	isohybrid --uefi ../$LAG_ISO
    cd -
    chmod -w $DEBIAN_DIR/isolinux/isolinux.bin
}

run_iso() {
    qemu-system-x86_64 -m $1 -smp $2 \
    -hda $3 \
    -cdrom $IMAGES_DIR/$LAG_ISO \
    -boot d -enable-kvm
}

"$@"
