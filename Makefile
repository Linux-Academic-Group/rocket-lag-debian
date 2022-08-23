# Directories
CONF_DIR    := conf
IMAGES_DIR  := images
DEBIAN_DIR  := $(IMAGES_DIR)/debian

# Files
DISK_IMAGE  := $(IMAGES_DIR)/storage.img
PRESEED_CFG := preseed.cfg
DEBIAN_ISO  := $(IMAGES_DIR)/debian-11.4.0-amd64.iso
DEBIAN_URL  := https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-11.4.0-amd64-DVD-1.iso
LAG_ISO     := $(IMAGES_DIR)/rocket-lag-debian.iso

# Default emulation settings
RAM   := 3G
NPROC := 2

# Colors
COL_BOLD   := $(shell tput bold)
COL_STATUS := $(COL_BOLD)$(shell tput setaf 4)
COL_BULLET := $(shell tput setaf 12)
COL_RECIPE := $(shell tput setaf 3)
COL_HEADER := $(COL_BOLD)$(shell tput setaf 2)
COL_RESET  := $(shell tput sgr0)
COL_CMD    := $(shell tput setaf 7)

.PHONY: directories help run build preseed

help:
	@echo '$(COL_HEADER)----------------------'
	@echo 'NO-LAG DEBIAN Makefile'
	@echo '----------------------$(COL_RESET)'
	@echo ''
	@echo '$(COL_BOLD)Requirements$(COL_RESET)'
	@echo '  $(COL_BULLET)*$(COL_RESET) wget, bsdtar, gzip, gunzip, cpio,'
	@echo '  $(COL_BULLET)*$(COL_RESET) genisoimage, qemu-system-x86_64'
	@echo ''
	@echo '$(COL_BOLD)Recipes$(COL_RESET)'
	@echo '  $(COL_BULLET)* $(COL_RECIPE)build$(COL_RESET) - builds the No-Lag Debian ISO'
	@echo '  $(COL_BULLET)* $(COL_RECIPE)run$(COL_RESET)   - runs No-Lag Debian in QEMU'
	@echo '  $(COL_BULLET)* $(COL_RECIPE)help$(COL_RESET)  - prints this help message'
	@echo ''
	@echo 'Running in QEMU requires a disk image file. This'
	@echo 'file can be generated manually with the command:'
	@echo ''
	@echo '    $(COL_CMD)qemu-img create '"'"'$(DISK_IMAGE)'"'"' <size>$(COL_RESET)'
	@echo ''
	@echo '...where $(COL_CMD)<size>$(COL_RESET) is expressed as 800M, 3.5G, etc.'
	@echo ''

directories:
	@mkdir -p -- $(IMAGES_DIR) $(DEBIAN_DIR)

run: $(LAG_ISO) $(DISK_IMAGE)
	@echo '$(COL_STATUS)Running No-Lag Debian in QEMU...$(COL_RESET)'
	qemu-system-x86_64 -m $(RAM) -smp $(NPROC) -hda $(DISK_IMAGE) \
		-cdrom $(LAG_ISO) -boot d -enable-kvm

build: preseed
	@echo '$(COL_STATUS)Building No-Lag Debian ISO...$(COL_RESET)'
	chmod +w -- $(DEBIAN_DIR)/isolinux/isolinux.bin
	cd $(DEBIAN_DIR) || exit 21
	genisoimage -r -J -b isolinux/isolinux.bin \
		-c isolinux/boot.cat \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		-o $(LAG_ISO) .
	cd - || exit 37
	chmod -w -- $(DEBIAN_DIR)/isolinux/isolinux.bin

preseed: $(DEBIAN_ISO)
	@echo '$(COL_STATUS)Preseeding Debian ISO...$(COL_RESET)'
	bsdtar -C $(DEBIAN_DIR) -xf $(DEBIAN_ISO)
	chmod +w -R -- $(DEBIAN_DIR)/install.amd
	gunzip $(DEBIAN_DIR)/install.amd/initrd.gz
	find $(CONF_DIR) $(PRESEED_CFG) | cpio -H newc -o -A -F $(DEBIAN_DIR)/install.amd/initrd
	gzip $(DEBIAN_DIR)/install.amd/initrd
	chmod -w -R -- $(DEBIAN_DIR)/install.amd/

$(DEBIAN_ISO): directories
	@echo '$(COL_STATUS)Downloading Debian ISO...$(COL_RESET)'
	@wget -nv --show-progress --progress=bar -O $(DEBIAN_ISO) $(DEBIAN_URL)

$(LAG_ISO): build
