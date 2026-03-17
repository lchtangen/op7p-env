# recovery/ — Recovery Toolkit

Tools and procedures for recovering Linux, Windows, and Android systems.
Covers: disk recovery, bootable USB creation, GRUB repair, Windows PE, Android fastboot.

---

## Directory Structure

```
recovery/
├── README.md                   This file — recovery overview
├── linux/                      Linux disk recovery and GRUB repair
│   ├── README.md               Linux recovery guide
│   └── recovery.sh             Interactive recovery menu (mount, clone, fsck, etc.)
├── android/                    Android recovery — TWRP, fastboot, ADB
│   ├── README.md               Android recovery guide
│   └── fastboot-recovery.sh    Fastboot flash / OTA recovery script
├── windows/                    Windows repair scripts
│   ├── README.md               Windows recovery guide
│   └── scripts/
│       ├── Remove-BitLocker.ps1    Disable BitLocker (prep for dual boot)
│       └── Shrink-Partition.ps1   Shrink Windows partition by 120 GB
└── bootable/                   Ventoy + ISO management
    ├── README.md               Bootable USB guide
    ├── iso/                    ISO storage (gitignored — large files)
    └── scripts/
        ├── ventoy-install.sh   Install/update Ventoy on USB drive
        └── iso-fetch.sh        Download Linux and Windows ISOs
```

---

## Key Tools (installed in Ubuntu)

```bash
testdisk        # Partition table recovery, file undelete
ddrescue        # Disk imaging with error recovery
fsck            # Filesystem check and repair (ext2/3/4, vfat, ntfs)
parted          # Partition management
ntfs-3g         # NTFS read/write support
wimtools        # Windows Imaging Format (WIM) tools
cryptsetup      # LUKS encryption / decryption
chntpw          # Windows registry editor (SAM, password reset)
gparted         # GUI partition editor (via VNC)
```

---

## Quick Reference

```bash
# Linux recovery
recover                                    # interactive menu (alias)
bash recovery/linux/recovery.sh

# Create bootable USB
bootable                                   # Ventoy install (alias)
bash recovery/bootable/scripts/ventoy-install.sh /dev/sdX

# Download ISOs
bash recovery/bootable/scripts/iso-fetch.sh

# Android recovery (from Termux)
adb reboot recovery                        # boot to TWRP
fastboot flash boot boot.img               # flash stock boot
fastboot reboot

# Disk clone
dd if=/dev/sdX of=/path/to/backup.img bs=4M status=progress
ddrescue /dev/sdX /path/to/backup.img recovery.log
```
