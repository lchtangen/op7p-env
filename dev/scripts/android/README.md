# dev/scripts/android/ — Android Root Scripts

Scripts that require Android root (Magisk `su`) from Termux.
These exist because the Ubuntu chroot has **no effective capabilities** — 
`sudo` is blocked by the Android 4.14 kernel (`CapEff: 0x0`).

---

## Why These Scripts Exist

Ubuntu runs as a chroot on the Android kernel. The chroot process has:
- `CapEff: 0000000000000000` — zero effective capabilities
- `sudo` fails: `su: cannot set groups: Operation not permitted`
- Sysfs/proc writes fail: `permission denied`

Root access is available only from **Android-side** via Magisk `su`.

---

## perf-tune-android.sh

Full SM8150 performance tuning applied directly from Android root.
Applies sysfs writes AND writes native Linux config files into the Ubuntu chroot.

```bash
# In Termux — get root first:
su

# Apply balanced tuning (recommended):
bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced

# Or with explicit chroot path for config file writing:
UBUNTU_ROOT=/data/user/0/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu \
  bash perf-tune-android.sh --balanced

# Available modes:
#   --max       performance governor, GPU max (585 MHz), WALT 75/60
#   --balanced  schedutil, GPU msm-adreno-tz + default_pwrlevel=2, WALT 80/65
#   --battery   schedutil, GPU powersave, WALT 95/85
#   --status    read-only status (no root required)
```

**What it tunes:**
| Target | Interface | Balanced value |
|--------|-----------|---------------|
| CPU governor (all clusters) | `/sys/devices/system/cpu/cpufreq/policyN/` | `schedutil` |
| schedutil rate_limit_us | same | `500 µs` |
| WALT sched_upmigrate | `/proc/sys/kernel/sched_upmigrate` | `80 80` |
| WALT sched_downmigrate | `/proc/sys/kernel/sched_downmigrate` | `65 65` |
| I/O scheduler (UFS) | `/sys/block/sda-sdf/queue/scheduler` | `deadline` |
| UFS read_ahead_kb | same | `512` |
| vm.swappiness | sysctl | `20` (was 160) |
| vm.dirty_ratio | sysctl | `30` |
| vm.vfs_cache_pressure | sysctl | `50` |
| net.core.rmem_max | sysctl | `67108864` (64 MB) |
| GPU governor | `/sys/class/kgsl/kgsl-3d0/devfreq/governor` | `msm-adreno-tz` |
| GPU default_pwrlevel | `/sys/class/kgsl/kgsl-3d0/default_pwrlevel` | `2` (427 MHz) |

**Config files written into chroot (if UBUNTU_ROOT found):**
- `$UBUNTU_ROOT/etc/sysctl.d/99-perf-vm.conf`
- `$UBUNTU_ROOT/etc/sysctl.d/99-perf-net.conf`
- `$UBUNTU_ROOT/etc/udev/rules.d/60-io-scheduler.rules`

---

## root-enter.sh

Enter the Ubuntu chroot as root from Android (Termux `su`).
Useful for running any Ubuntu command that requires root.

```bash
# In Termux:
su
bash /storage/emulated/0/dev/scripts/android/root-enter.sh

# Inside chroot as root — now sudo works:
bash /home/ltangen/dev/scripts/linux/perf-tune.sh --balanced
bash /home/ltangen/dev/scripts/linux/docker-optimize.sh
```

The script auto-detects the Ubuntu chroot path. If it fails:
```bash
UBUNTU_ROOT=/your/chroot/path bash root-enter.sh
```

---

## Common Chroot Paths (proot-distro)

```
/data/user/0/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu
/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu
/data/local/ubuntu
```
