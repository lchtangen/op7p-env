# Custom Kernel Guide — OnePlus 7 Pro GM1913
**Device:** OnePlus 7 Pro (GM1913 EU) | Snapdragon 855 (SM8150) | Magisk rooted
**Goal:** Replace stock 4.14.180-perf+ with performance-optimized custom kernel
**Risk:** Medium — always have TWRP + OxygenOS full backup before flashing

---

## Why Flash a Custom Kernel?

| Feature | Stock 4.14.180-perf+ | Custom Kernel |
|---------|---------------------|---------------|
| CPU governor tuning | Basic | Advanced schedutil + HMP |
| I/O scheduler | CFQ only | deadline, mq-deadline, BFQ |
| TCP congestion control | cubic | BBR, Westwood+ |
| Zram compression | lz4 | zstd (faster, better ratio) |
| GPU OC/UV | No | Yes (Adreno 640) |
| wakelock control | No | Yes |
| KernelSU support | No | Yes (on supported builds) |
| Build compiler | GCC | LLVM/Clang (faster, better ARM64) |
| Kernel version | 4.14.180 | 4.14.x + patches (stable fork) |

---

## Recommended Kernels for GM1913

### 1. Kirisakura-NG (Best overall)
- **Base:** CAF LA.UM.9.1 (Linux 4.14) + upstream patches
- **Compiler:** LLVM 17 (clang, faster ARM64 code)
- **Features:** EAS, schedutil+, AnyKernel3 flash, GPU OC, zstd zram
- **GitHub:** `https://github.com/freak07/Kirisakura_OP7Pro`
- **XDA:** Search "Kirisakura OnePlus 7 Pro" on XDA-Developers

### 2. Sultan Kernel
- **Base:** 4.14 CAF + Google mainline patches
- **Compiler:** LLVM
- **Features:** Clean, minimal, stable
- **GitHub:** `https://github.com/sultanxda/sultan-kernel-op7pro` (check for latest)

### 3. KernelSU + Any Kernel (Alternative to Magisk)
- **What:** Root managed in-kernel (more stable than Magisk)
- **Use with:** Flash custom kernel with KernelSU support built in
- **GitHub:** `https://github.com/tiann/KernelSU`
- **Note:** KernelSU replaces Magisk — choose one

---

## Prerequisites

```bash
# On phone (Ubuntu chroot):
ollama list       # note model names — they survive kernel flash
ls ~/projects/    # ensure recent git commits pushed to GitHub

# Required:
# - TWRP installed (replaces or alongside OxygenOS recovery)
# - Android bootloader: UNLOCKED (already done if Magisk is installed)
# - ADB + fastboot on PC (optional but recommended)
# - Full OxygenOS backup (TWRP → Backup → select all partitions)
```

---

## Step-by-Step: Flash Custom Kernel

### Phase 1 — Backup
```bash
# On PC with ADB:
adb backup -apk -shared -all -f oneplus7pro-backup-$(date +%Y%m%d).ab

# Or via TWRP (better):
# Power off → hold Vol+ + Power → TWRP → Backup → Select: Boot, System, Data
```

### Phase 2 — Download Kernel
```bash
# Download to phone via Ubuntu chroot:
mkdir -p ~/recovery/android/kernels
cd ~/recovery/android/kernels

# Kirisakura latest release (check GitHub for actual latest URL):
# wget https://github.com/freak07/Kirisakura_OP7Pro/releases/download/vX.X/Kirisakura_X.X_OP7Pro.zip

# Verify checksum if provided:
# sha256sum Kirisakura_*.zip
```

### Phase 3 — Flash via Magisk (Preferred — no wipe)
```bash
# In Magisk Manager (Android app):
# Magisk → Install → Install to Inactive Slot (for A/B)
# OR
# Magisk → Modules → Flash ZIP → select kernel zip

# Reboot to verify:
# Settings → About → Kernel version should show new kernel
```

### Phase 4 — Flash via TWRP (Alternative)
```
1. Copy kernel zip to /sdcard/
2. Power off → hold Vol+ + Power (TWRP)
3. Install → select kernel zip
4. Wipe cache/dalvik
5. Reboot System
```

### Phase 5 — Verify
```bash
# After boot, in Ubuntu chroot:
uname -r     # should show new kernel version
sysinfo      # check CPU governor, new features

# Verify Ollama/Docker still work:
ollama list
docker ps
```

---

## Post-Kernel: Apply Performance Tuning

After flashing, custom kernels unlock more tuning options:

```bash
# Run performance tuner (now with new schedulers available):
sudo bash ~/dev/scripts/linux/perf-tune.sh --balanced

# New options available on custom kernels:
# I/O: mq-deadline, BFQ (better than cfq)
# TCP: BBR congestion control (built into most custom kernels)
# Zram: zstd compression (30% faster than lz4)
```

### Configure Zram with zstd (post custom kernel)
```bash
# If custom kernel supports zstd zram:
sudo bash << 'EOF'
swapoff /dev/zram0 2>/dev/null || true
echo 0 > /sys/block/zram0/reset
echo "zstd" > /sys/block/zram0/comp_algorithm
echo "6G" > /sys/block/zram0/disksize    # 6GB zram for 12GB device
mkswap /dev/zram0
swapon /dev/zram0 -p 100
sysctl -w vm.swappiness=20
echo "zstd zram active: $(cat /sys/block/zram0/comp_algorithm)"
EOF
```

---

## KernelSU (Optional — replaces Magisk)

```bash
# 1. Flash kernel with KernelSU built in (check kernel release notes)
# 2. Install KernelSU Manager app (from GitHub releases)
# 3. Migrate Magisk modules → KernelSU modules (most are compatible)

# Advantages over Magisk:
# - Root managed in kernel space (more reliable)
# - Better SELinux integration
# - Smaller attack surface
# - Works with OEM fastboot on some devices
```

---

## Recovery: If Boot Fails

```bash
# Option 1: TWRP → Restore previous backup
# Option 2: Fastboot flash boot.img (stock)
#   fastboot flash boot stock-boot.img
#   fastboot reboot

# Stock boot images: keep a copy at ~/recovery/android/
# Download from: https://oxygenos.oneplus.net/
```

---

## Mainline Linux Status (SM8150)

> **Not recommended for daily use yet** — informational only

The SM8150 has partial mainline Linux support (6.x):
- Works: USB, basic storage, some GPIO
- Missing: cellular modem, GPU (Adreno 640 upstreaming in progress), camera, sensors
- Project: `https://github.com/Project-Silicium` (SM8150 mainlining)
- ETA for usable mainline: ~2026-2027

For full Linux distro on hardware: stick to 4.14-based custom kernel.

---

*Last updated: 2026-03-17 | Device: GM1913 EU | Kernel base: 4.14*
