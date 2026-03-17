# recovery/bootable/ — Bootable USB & Multi-Distro

Ventoy-based bootable USB drive for installing and recovering Linux/Windows on any PC.
Supports persistence, Secure Boot, and multiple ISOs from one USB drive.

---

## Directory Structure

```
bootable/
├── README.md               This file
├── iso/                    ISO storage — copy to Ventoy USB /ventoy/
└── scripts/
    ├── ventoy-install.sh   Install or update Ventoy on USB drive
    └── iso-fetch.sh        Download ISOs (Ubuntu, Kali, Debian, Win11, etc.)
```

---

## Ventoy Setup

```bash
# Install Ventoy to USB drive (replaces partition table — destructive):
bootable                                               # alias
sudo bash ~/recovery/bootable/scripts/ventoy-install.sh /dev/sdX

# After install: copy ISOs to USB /ventoy/ directory
cp ~/recovery/bootable/iso/*.iso /media/ltangen/Ventoy/
```

---

## Download ISOs

```bash
bash ~/recovery/bootable/scripts/iso-fetch.sh
```

| OS | Version | Size | Use |
|----|---------|------|-----|
| Ubuntu Desktop | 24.04.2 | ~5.6 GB | Desktop install |
| Kali Linux | 2024.4 | ~4.0 GB | Penetration testing |
| Parted Magic | 2024 | ~800 MB | Disk partitioning, recovery |
| Debian | 12.5 | ~3.9 GB | Minimal server |
| Fedora | 41 | ~2.3 GB | RPM-based alternative |
| Windows 11 ARM64 | 24H2 | ~5.5 GB | Windows recovery / ARM64 PC |
| Tails | 6.4 | ~1.3 GB | Anonymous, amnesic OS |

---

## Ventoy Configuration (ventoy.json)

For persistence and Secure Boot, create `/ventoy/ventoy.json` on the USB:

```json
{
  "persistence": [
    {
      "image": "/ventoy/ubuntu-24.04.2-desktop-amd64.iso",
      "backend": "/ventoy/ubuntu-persistence.dat"
    }
  ],
  "control": [
    {
      "VTOY_DEFAULT_SEARCH_ROOT": "/ventoy"
    }
  ]
}
```

Create persistence file:
```bash
dd if=/dev/zero of=/media/ltangen/Ventoy/ubuntu-persistence.dat bs=1M count=4096
mkfs.ext4 -L persistence /media/ltangen/Ventoy/ubuntu-persistence.dat
```

---

## Secure Boot

Ventoy supports Secure Boot via MOK (Machine Owner Key) enrollment.
Run once per machine: Ventoy boot menu → Enroll MOK → follow prompts.

---

## OnePlus 7 Pro as Bootable USB

The OP7P can present itself as a USB storage device:
```
Android Settings → Developer Options → USB Configuration → MTP + USB Storage
```

Or via ADB:
```bash
adb shell svc usb setFunctions mtp
```

Copy ISOs to exposed storage, then Ventoy reads from the device's internal storage partition.
