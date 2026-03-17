# magisk-root.md — Magisk Root Workflow

Magisk provides systemless root on the OnePlus 7 Pro (GM1913).
This doc covers root workflow, init.d boot scripts, modules, and safe use from the Ubuntu chroot.

---

## Magisk Overview

```
Magisk Manager (app)  ←→  Magisk daemon (magiskd)
                              └── /data/adb/magisk/     (core files)
                              └── /data/adb/modules/    (installed modules)
                              └── /data/adb/service.d/  (init.d scripts)
                              └── /data/adb/post-fs-data.d/  (early scripts)
```

- **Systemless:** does not modify /system partition
- **MagiskHide / DenyList:** hide root from specific apps
- **Zygisk:** inject into Android runtime for module support

---

## Getting Root from Termux

```bash
# Basic root shell:
su

# Run single command as root:
su -c "command"

# Run script as root:
su -c "bash /path/to/script.sh"

# Check root access:
su -c "id"    # → uid=0(root) gid=0(root)
```

---

## Running Root Scripts from Ubuntu Path

The Ubuntu home directory is on Android storage. From Termux `su`:

```bash
# If home is on internal storage (sdcard):
su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced"

# If home is in Termux data:
su -c "bash /data/user/0/com.termux/files/home/dev/scripts/android/perf-tune-android.sh --balanced"

# Entering Ubuntu chroot as root:
su -c "bash /storage/emulated/0/dev/scripts/android/root-enter.sh"
```

---

## Magisk init.d (Boot-Time Scripts)

Scripts in `/data/adb/service.d/` run as root after Android boot.
Written by `dev/scripts/android/perf-tune-android.sh` automatically.

```bash
# View boot scripts:
ls /data/adb/service.d/
cat /data/adb/service.d/99-perf-tune.sh

# Manually add/edit (from Termux su):
su
nano /data/adb/service.d/99-perf-tune.sh
chmod +x /data/adb/service.d/99-perf-tune.sh
```

**Note:** init.d scripts run in Android context — use Android shell syntax (`/system/bin/sh`), not bash.

---

## Useful Magisk Modules

| Module | Purpose |
|--------|---------|
| LSPosed | Xposed framework in Zygisk — app hooks |
| Shamiko | MagiskHide successor — hide from DenyList |
| MagiskSSH | SSH server for Android |
| KernelSU | Alternative root (in-kernel, replaces Magisk) |

---

## KernelSU (Alternative to Magisk)

KernelSU integrates root into the kernel itself — more stable than userspace Magisk.
**Requires:** custom kernel with KernelSU built in (Kirisakura-NG supports it).

```
Pros: in-kernel root, better SELinux, smaller attack surface
Cons: replaces Magisk — choose one; modules may differ
```

Guide: `~/docs/android/kernel-custom.md` — Section: KernelSU

---

## Safety

- **Do not run `su` as ltangen unless needed** — reduces exposure
- **Magisk DenyList** — add banking/payment apps to hide root
- **Backup before module installs** — buggy modules can bootloop
- **TWRP always available** — if bootloop: Vol+ + Power → TWRP → Restore backup
