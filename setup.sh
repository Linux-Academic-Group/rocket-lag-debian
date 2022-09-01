#!/bin/bash

IMAGES_DIR=images
DISK_IMAGE=$IMAGES_DIR/storage.img
DEBIAN_ISO=$IMAGES_DIR/debian-11.4.0-amd64.iso
DEBIAN_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-11.4.0-amd64-DVD-1.iso
DEBIAN_DIR=$IMAGES_DIR/debian
LAG_ISO=rocket-lag-debian.iso
POOL_DIR=${DEBIAN_DIR}/pool/main

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

add_debs() {
    # This requires debian-based distro, use docker if needed
    # TODO: add dockerfile for this step
    apt update
    PACKAGES="mosquitto tint2" # add any other packages here, separate with space
    ALL_PACKAGES=$(apt-cache depends --recurse --no-recommends \
        --no-suggests --no-conflicts --no-breaks --no-replaces \
        --no-enhances --no-pre-depends ${PACKAGES} | grep "^\w")
    for i in ${ALL_PACKAGES}; do
        # get right directories to download the iso into
        pkg_dir=$POOL_DIR/$(apt-get download --print-uris $i | awk -F "/" '{printf "%s/%s\n", $(NF-2), $(NF-1)}')
        mkdir -p $pkg_dir
        (cd $pkg_dir && apt-get download $i)
    done
    # Package the pool and generate checksums
    apt-ftparchive generate config-deb
    sed -i '/MD5Sum:/,$d' $DEBIAN_DIR/dists/bullseye/Release
    apt-ftparchive release $DEBIAN_DIR/dists/bullseye >> $DEBIAN_DIR/dists/bullseye/Release
    (cd $DEBIAN_DIR; md5sum `find ! -name "md5sum.txt" ! -path "./isolinux/*" -follow -type f` > md5sum.txt)
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
		--eltorito-boot boot/grub/efi.img \
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
