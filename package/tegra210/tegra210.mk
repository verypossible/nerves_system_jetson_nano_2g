################################################################################
#
# Linux Tegra210 Board Support Package
#
################################################################################

TEGRA210_VERSION = 32.5.0
TEGRA210_SITE = https://developer.nvidia.com/embedded/L4T/r32_Release_v5.0/T210
TEGRA210_SOURCE = Tegra210_Linux_R$(TEGRA210_VERSION)_aarch64.tbz2
# TODO: Double check this.
TEGRA210_LICENSE = NVIDIA Customer Software Agreement
TEGRA210_LICENSE_FILES = bootloader/LICENSE \
			 bootloader/LICENSE.chkbdinfo \
			 bootloader/LICENSE.mkbctpart \
			 bootloader/LICENSE.mkbootimg \
			 bootloader/LICENSE.mkgpt \
			 bootloader/LICENSE.mksparse \
			 bootloader/LICENSE.tos-mon-only.img.arm-trusted-firmware \
			 bootloader/LICENSE.u-boot \
			 bootloader/t210ref/LICENSE.cboot \
			 bootloader/t210ref/LICENSE.sc7entry-firmware

TEGRA210_REDISTRIBUTE = NO
TEGRA210_INSTALL_IMAGES = YES
TEGRA210_DEPENDENCIES = linux uboot
HOST_TEGRA210_DEPENDENCIES = linux host-python

# Collects files required for tegraflash.py
# Also updates the flash.xml config file with values for the Jetson Nano SD (p3450-0000)
define TEGRA210_CONFIGURE_CMDS
	cp $(@D)/bootloader/t210ref/nvtboot.bin $(@D)/bootloader/nvtboot.bin
	cp $(@D)/bootloader/t210ref/cboot.bin $(@D)/bootloader/cboot.bin
	cp $(@D)/bootloader/t210ref/warmboot.bin $(@D)/bootloader/warmboot.bin
	cp $(@D)/bootloader/t210ref/sc7entry-firmware.bin $(@D)/bootloader/sc7entry-firmware.bin
	cp $(@D)/bootloader/t210ref/BCT/P2894_A00_Samsung_3GB_lpddr4_204Mhz_P984_v2.cfg \
		$(@D)/bootloader/P2894_A00_Samsung_3GB_lpddr4_204Mhz_P984_v2.cfg
	cp $(@D)/bootloader/t210ref/cfg/flash_l4t_t210_spi_sd_p3448.xml $(@D)/bootloader/flash.xml

	sed -i -e 's/NXC/NVC/' \
		-e 's/NVCTYPE/bootloader/' \
		-e 's/NVCFILE/nvtboot.bin/' \
		-e 's/VERFILE/qspi_bootblob_ver.txt/g' \
		-e 's/EBTFILE/cboot.bin/' \
		-e 's/TBCFILE/nvtboot_cpu.bin/' \
		-e 's/TXC/TBC/' \
		-e 's/TXS/TOS/' \
		-e 's/TOSFILE/tos-mon-only.img/' \
		-e 's/TBCTYPE/bootloader/' \
		-e 's/DTBFILE/tegra210-p3448-0003-p3542-0000.dtb/' \
		-e 's/WB0TYPE/WB0/' \
		-e 's/WB0FILE/warmboot.bin/' \
		-e 's/BXF/BPF/' \
		-e 's/BPFFILE/sc7entry-firmware.bin/' \
		-e 's/WX0/WB0/' \
		-e 's/DXB/DTB/' \
		-e 's/EXS/EKS/' \
		-e 's/EKSFILE/eks.img/' \
		-e 's/FBTYPE/data/' \
		-e 's/LNXFILE/boot.img/' \
		-e 's/APPUUID//' \
		-e 's/APPFILE/system.img/' \
		-e '/FBFILE/d' \
		-e '/BPFDTB-FILE/d' \
		-e "s/APPSIZE/"$(BR2_TARGET_ROOTFS_EXT2_SIZE)"/" \
		$(@D)/bootloader/flash.xml
endef

define COPY_DTB_FOR_SIGNING
	cp $(BINARIES_DIR)/tegra210-p3448-0003-p3542-0000.dtb \
		$(@D)/bootloader/tegra210-p3448-0003-p3542-0000.dtb
endef

TEGRA210_PRE_BUILD_HOOKS += COPY_DTB_FOR_SIGNING

define TEGRA210_BUILD_CMDS
	cd $(@D)/bootloader && \
	./mkbootimg --kernel $(BINARIES_DIR)/u-boot.bin \
	--ramdisk /dev/null \
	--board mmcblk0p1 \
	--output $(@D)/bootloader/boot.img \
	--cmdline 'root=/dev/mmcblk0p1 r0 rootwait rootfstype=squashfs console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0'

	cd $(@D)/bootloader && \
	./tegraflash.py --bl cboot.bin \
	--bct P2894_A00_Samsung_3GB_lpddr4_204Mhz_P984_v2.cfg \
	--odmdata 0x94000 \
	--bldtb tegra210-p3448-0003-p3542-0000.dtb \
	--applet nvtboot_recovery.bin \
	--cmd "sign" \
	--cfg flash.xml \
	--chip 0x21 \
	--bins "EBT cboot.bin; DTB tegra210-p3448-0003-p3542-0000.dtb"

endef

define TEGRA210_INSTALL_IMAGES_CMDS
	$(INSTALL) -m 0644 $(@D)/bootloader/boot.img $(BINARIES_DIR)/boot.img
	$(INSTALL) -m 0644 $(@D)/bootloader/bmp.blob $(BINARIES_DIR)/bmp.blob
	$(INSTALL) -m 0644 $(@D)/bootloader/rp4.blob $(BINARIES_DIR)/rp4.blob
	$(INSTALL) -m 0644 $(@D)/bootloader/eks.img $(BINARIES_DIR)/eks.img
	$(INSTALL) -D -m 0644 $(@D)/bootloader/l4t_initrd.img $(BINARIES_DIR)/initrd

	$(INSTALL) -m 0644 $(@D)/bootloader/signed/boot.img.encrypt $(BINARIES_DIR)/boot.img.encrypt
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/cboot.bin.encrypt $(BINARIES_DIR)/cboot.bin.encrypt
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/flash.xml $(BINARIES_DIR)/flash.xml
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/flash.xml.bin $(BINARIES_DIR)/flash.xml.bin
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/nvtboot.bin.encrypt $(BINARIES_DIR)/nvtboot.bin.encrypt
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/nvtboot_cpu.bin.encrypt $(BINARIES_DIR)/nvtboot_cpu.bin.encrypt
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/P2894_A00_Samsung_3GB_lpddr4_204Mhz_P984_v2.bct \
		$(BINARIES_DIR)/P2894_A00_Samsung_3GB_lpddr4_204Mhz_P984_v2.bct
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/sc7entry-firmware.bin.encrypt $(BINARIES_DIR)/sc7entry-firmware.bin.encrypt
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/tegra210-p3448-0003-p3542-0000.dtb.encrypt \
		$(BINARIES_DIR)/tegra210-p3448-0003-p3542-0000.dtb.encrypt
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/tos-mon-only.img.encrypt $(BINARIES_DIR)/tos-mon-only.img.encrypt
	$(INSTALL) -m 0644 $(@D)/bootloader/signed/warmboot.bin.encrypt $(BINARIES_DIR)/warmboot.bin.encrypt
endef

define TEGRA210_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/bootloader/extlinux.conf $(TARGET_DIR)/boot/extlinux/extlinux.conf
	$(INSTALL) -D -m 0644 $(@D)/bootloader/l4t_initrd.img $(TARGET_DIR)/boot/initrd
	$(INSTALL) -D -m 0644 $(@D)/bootloader/nv_boot_control.conf $(TARGET_DIR)/etc/nv_boot_control.conf

	sed -i /TNSPEC/d $(TARGET_DIR)/etc/nv_boot_control.conf
	sed -i '$$ a TNSPEC 3448-300---1-0-jetson-nano-qspi-sd-mmcblk0p1' $(TARGET_DIR)/etc/nv_boot_control.conf
	sed -i /TEGRA_CHIPID/d $(TARGET_DIR)/etc/nv_boot_control.conf
	sed -i '$$ a TEGRA_CHIPID 0x21' $(TARGET_DIR)/etc/nv_boot_control.conf
	sed -i /TEGRA_OTA_BOOT_DEVICE/d $(TARGET_DIR)/etc/nv_boot_control.conf
	sed -i '$$ a TEGRA_OTA_BOOT_DEVICE /dev/mtdblock0' $(TARGET_DIR)/etc/nv_boot_control.conf
	sed -i /TEGRA_OTA_GPT_DEVICE/d $(TARGET_DIR)/etc/nv_boot_control.conf
	sed -i '$$ a TEGRA_OTA_GPT_DEVICE /dev/mtdblock0' $(TARGET_DIR)/etc/nv_boot_control.conf

	$(INSTALL) -D -m 0644 -D $(@D)/bootloader/tegra210-p3448-0003-p3542-0000.dtb \
		$(TARGET_DIR)/boot/tegra210-p3448-0003-p3542-0000.dtb
	dpkg-deb -x $(@D)/nv_tegra/l4t_deb_packages/nvidia-l4t-xusb-firmware_32.5.0-20210115145440_arm64.deb $(TARGET_DIR)
	dpkg-deb -x $(@D)/nv_tegra/l4t_deb_packages/nvidia-l4t-cuda_32.5.0-20210115145440_arm64.deb $(TARGET_DIR)
	dpkg-deb -x $(@D)/nv_tegra/l4t_deb_packages/nvidia-l4t-firmware_32.5.0-20210115145440_arm64.deb $(TARGET_DIR)
	dpkg-deb -x $(@D)/nv_tegra/l4t_deb_packages/nvidia-l4t-core_32.5.0-20210115145440_arm64.deb $(TARGET_DIR)

	# Clean up /etc/ld.so.conf.d
	rm -rf $(TARGET_DIR)/etc/ld.so.conf.d
endef

$(eval $(generic-package))
$(eval $(host-generic-package))
