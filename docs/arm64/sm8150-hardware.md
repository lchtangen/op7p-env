# SM8150 Hardware Reference — OnePlus 7 Pro GM1913

Complete sysfs path reference, power management interfaces, and hardware specs
for Qualcomm Snapdragon 855 (SM8150) on Android kernel 4.14.180-perf+.

---

## CPU — Kryo 485 (ARM Cortex-A76 derivative)

### Cluster Layout

| Cluster | Cores | CPUs | Max Freq | Governor | Use |
|---------|-------|------|---------|---------|-----|
| LITTLE | Kryo 485 Silver | cpu0–cpu3 | 1785.6 MHz | schedutil | Efficiency, OS tasks |
| MID | Kryo 485 Gold | cpu4–cpu6 | 2419.2 MHz | schedutil | Balanced workloads |
| PRIME | Kryo 485 Gold+ | cpu7 | 2841.6 MHz | schedutil | Peak single-thread |

### CPU sysfs Paths

```bash
# Per-cluster (policy) paths — policy0=LITTLE, policy4=MID, policy7=PRIME
/sys/devices/system/cpu/cpufreq/policy0/
/sys/devices/system/cpu/cpufreq/policy4/
/sys/devices/system/cpu/cpufreq/policy7/

# Key files per policy:
scaling_governor        # read/write: schedutil|performance|powersave|ondemand
cpuinfo_cur_freq        # read: current frequency in kHz
cpuinfo_max_freq        # read: maximum frequency in kHz
cpuinfo_min_freq        # read: minimum frequency in kHz
scaling_available_governors    # read: list of available governors
schedutil/rate_limit_us        # write: governor response time (500 = fast)

# Per-CPU online control
/sys/devices/system/cpu/cpu0/online   # 0=offline, 1=online (cpu0 always on)
```

### WALT Scheduler (Qualcomm CAF)

```bash
# Migration thresholds — tab-separated pairs (LITTLE→MID, MID→PRIME)
/proc/sys/kernel/sched_upmigrate       # default: 95 95 | tuned: 80 80
/proc/sys/kernel/sched_downmigrate     # default: 85 85 | tuned: 65 65
/proc/sys/kernel/sched_boost           # 0=off, 1=force all tasks to big cores
/proc/sys/kernel/sched_walt_rotate_big_tasks   # 1=rotate across big cores
/proc/sys/kernel/sched_migration_cost_ns       # scheduler migration cost (500000)
/proc/sys/kernel/sched_min_granularity_ns      # min scheduling slice (3000000)
/proc/sys/kernel/sched_wakeup_granularity_ns   # wakeup preemption threshold (4000000)
```

---

## GPU — Adreno 640v2 (KGSL)

### Power Levels

| Level | Frequency | Notes |
|-------|-----------|-------|
| 0 | 585 MHz | Maximum — performance mode |
| 1 | 499 MHz | |
| 2 | 427 MHz | Default balanced |
| 3 | 345 MHz | |
| 4 | 257 MHz | Minimum — power save |

### GPU sysfs Paths

```bash
/sys/class/kgsl/kgsl-3d0/
  devfreq/governor           # msm-adreno-tz | performance | powersave
  min_pwrlevel               # 0–4 (0=max freq, 4=min freq)
  max_pwrlevel               # 0–4
  default_pwrlevel           # 0–4 (starting level when GPU activates)
  gpuclk                     # current GPU clock in Hz (read-only)
  gpu_available_frequencies  # list of available frequencies
  acd_enable_by_level        # Adaptive Clock Distribution (1=enable)
  
# devfreq sub-paths:
devfreq/governor             # same as above
devfreq/cur_freq             # current frequency
devfreq/min_freq             # minimum allowed frequency
devfreq/max_freq             # maximum allowed frequency
```

---

## Storage — UFS 3.0

### Block Devices

| Device | Partition |
|--------|-----------|
| sda | userdata (main storage) |
| sdb | system |
| sdc | vendor |
| sdd | odm |
| sde | product |
| sdf | misc / other |

### I/O Scheduler sysfs Paths

```bash
/sys/block/sda/queue/
  scheduler          # [cfq] deadline noop — write: "deadline" for best latency
  read_ahead_kb      # readahead size (512 = good for sequential)
  nr_requests        # queue depth (256 for UFS)
  add_random         # entropy contribution (0=disable for perf)
  rotational         # 0 = SSD/UFS (no rotation)
  
# Native Linux persistence:
/etc/udev/rules.d/60-io-scheduler.rules
```

---

## Memory

```bash
# RAM info
/proc/meminfo                     # MemTotal, MemFree, Buffers, Cached, SwapTotal
/proc/sys/vm/swappiness           # default Android: 160 | tuned: 20
/proc/sys/vm/dirty_ratio          # max dirty pages before sync: 30
/proc/sys/vm/dirty_background_ratio   # background writeback: 10
/proc/sys/vm/vfs_cache_pressure   # inode/dentry cache pressure: 50
/proc/sys/vm/page-cluster         # swap readahead: 0 (SSD-like)

# Zram (swap compression)
/sys/block/zram0/comp_algorithm   # lz4 (stock) | zstd (custom kernel only)
/sys/block/zram0/disksize         # zram device size

# Transparent Huge Pages
/sys/kernel/mm/transparent_hugepage/enabled
/sys/kernel/mm/transparent_hugepage/defrag
```

---

## Network

```bash
# TCP/IP sysctl paths:
/proc/sys/net/core/rmem_max           # receive buffer max: 67108864 (64 MB)
/proc/sys/net/core/wmem_max           # send buffer max: 67108864 (64 MB)
/proc/sys/net/core/netdev_max_backlog # packet backlog: 16384
/proc/sys/net/ipv4/tcp_rmem           # tcp receive: "4096 4194304 67108864"
/proc/sys/net/ipv4/tcp_wmem           # tcp send: "4096 4194304 67108864"
/proc/sys/net/ipv4/tcp_congestion_control   # bbr | cubic
/proc/sys/net/ipv4/tcp_fastopen       # 0|1|3

# Native Linux persistence:
/etc/sysctl.d/99-perf-net.conf
```

---

## Power / Battery

```bash
/sys/class/power_supply/battery/
  capacity               # battery % (0–100)
  status                 # Charging | Discharging | Full | Not charging
  voltage_now            # voltage in µV
  current_now            # current in µA (negative = discharging)
  temp                   # temperature in tenths of °C
  health                 # Good | Overheat | Dead | Over voltage
  technology             # Li-ion
  
/sys/class/power_supply/usb/
  online                 # 1 if USB connected
  
/sys/class/thermal/thermal_zone*/
  temp                   # thermal zone temperature in millidegrees C
  type                   # zone name (cpu0, gpu, etc.)
```

---

## Kernel Tuning — Native Linux Config Files

| Config File | Content | Applied By |
|-------------|---------|-----------|
| `/etc/sysctl.d/99-perf-vm.conf` | VM params (swappiness, dirty ratios) | `systemd-sysctl` at boot |
| `/etc/sysctl.d/99-perf-net.conf` | Network buffers, TCP CC | `systemd-sysctl` at boot |
| `/etc/udev/rules.d/60-io-scheduler.rules` | I/O scheduler for UFS | `udev` on device registration |
| `/etc/systemd/system/perf-tune.service` | CPU governor, WALT, GPU at boot | `systemd` oneshot |

Apply: `sudo bash ~/dev/scripts/linux/perf-tune.sh --balanced`
(Or from Termux: `su -c "bash .../perf-tune-android.sh --balanced"`)

---

## Kernel Version

```
Linux 4.14.180-perf+ (Qualcomm CAF fork)
Compiler: clang 10.0.7 for Android NDK
Build: 2023-03-23
Architecture: aarch64
Missing (vs mainline 6.x): BBR module, zstd zram, BFQ I/O, io_uring, eBPF full
```

### Custom Kernel Availability

Kirisakura-NG for GM1913 adds: LLVM 17 build, BBR, BFQ, zstd zram, GPU OC/UV.
Guide: `~/docs/android/kernel-custom.md`
