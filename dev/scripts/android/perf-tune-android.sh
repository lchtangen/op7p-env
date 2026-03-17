#!/bin/bash
# perf-tune-android.sh — SM8150 tuning from Termux/Android root (Magisk su)
# Required because Ubuntu chroot sessions run without root capabilities.
# Run from Termux: su -c "bash /path/to/perf-tune-android.sh [--max|--balanced|--battery|--status]"
#
# This script applies sysfs/proc writes that require root and cannot be done
# from inside the Ubuntu chroot. It also writes config files INTO the chroot
# at their native Linux paths (/etc/sysctl.d/, /etc/udev/rules.d/, systemd).
#
# The Ubuntu chroot root is auto-detected. Override: UBUNTU_ROOT=/your/path

MODE="${1:---balanced}"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
ws()   { echo "$2" > "$1" 2>/dev/null && ok "$(basename $1) = $2" || warn "skip: $(basename $1)"; }

# ─── Find Ubuntu chroot ────────────────────────────────────────────────────────
if [ -z "${UBUNTU_ROOT:-}" ]; then
    for candidate in \
        /data/user/0/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu \
        /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu \
        /data/local/ubuntu; do
        if [ -d "${candidate}/etc" ]; then
            UBUNTU_ROOT="$candidate"; break
        fi
    done
fi

if [ -z "${UBUNTU_ROOT:-}" ]; then
    warn "Ubuntu chroot not found — sysfs writes will still apply to Android kernel"
    warn "Set UBUNTU_ROOT=/path/to/chroot to also write config files into it"
    UBUNTU_ROOT=""
fi

show_status() {
    echo -e "\n${BOLD}SM8150 Status:${RESET}"
    for p in 0 4 7; do
        GOV=$(cat /sys/devices/system/cpu/cpufreq/policy${p}/scaling_governor 2>/dev/null || echo "N/A")
        FREQ=$(cat /sys/devices/system/cpu/cpufreq/policy${p}/cpuinfo_cur_freq 2>/dev/null || echo "0")
        MAXF=$(cat /sys/devices/system/cpu/cpufreq/policy${p}/cpuinfo_max_freq 2>/dev/null || echo "0")
        FREQ=${FREQ:-0}; MAXF=${MAXF:-0}
        printf "  CPU policy%d: %-12s  cur=%4d  max=%4d MHz\n" "$p" "$GOV" "$((FREQ/1000))" "$((MAXF/1000))"
    done
    echo "  swappiness:     $(cat /proc/sys/vm/swappiness 2>/dev/null)"
    echo "  dirty_ratio:    $(cat /proc/sys/vm/dirty_ratio 2>/dev/null)"
    echo "  TCP CC:         $(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)"
    echo "  sched_upmigrate: $(cat /proc/sys/kernel/sched_upmigrate 2>/dev/null || echo N/A)"
    echo "  I/O (sda):      $(cat /sys/block/sda/queue/scheduler 2>/dev/null || echo N/A)"
    GPU="/sys/class/kgsl/kgsl-3d0"
    printf "  GPU governor:   %s  |  min_pwrlevel: %s  |  default: %s\n" \
        "$(cat ${GPU}/devfreq/governor 2>/dev/null || echo N/A)" \
        "$(cat ${GPU}/min_pwrlevel 2>/dev/null || echo N/A)" \
        "$(cat ${GPU}/default_pwrlevel 2>/dev/null || echo N/A)"
}

if [ "$MODE" = "--status" ]; then show_status; exit 0; fi

if [ "$(id -u)" != "0" ]; then
    warn "Not root. Run: su -c \"bash $0 $MODE\""
    show_status; exit 1
fi

echo -e "\n${BOLD}${CYAN}SM8150 Perf Tune (Android root) | Mode: ${MODE}${RESET}\n"

case "$MODE" in
    --max)      CPU_GOV="performance"; SCHED_UP="75	75"; SCHED_DN="60	60"; BOOST=1
                SWAP=10;  DIRTY=40; DIRTY_BG=15; GPU_GOV="performance"; GPU_MIN=0; GPU_DEF=0 ;;
    --balanced) CPU_GOV="schedutil";   SCHED_UP="80	80"; SCHED_DN="65	65"; BOOST=0
                SWAP=20; DIRTY=30; DIRTY_BG=10; GPU_GOV="msm-adreno-tz"; GPU_MIN=4; GPU_DEF=2 ;;
    --battery)  CPU_GOV="schedutil";   SCHED_UP="95	95"; SCHED_DN="85	85"; BOOST=0
                SWAP=40; DIRTY=20; DIRTY_BG=5;  GPU_GOV="powersave"; GPU_MIN=4; GPU_DEF=4 ;;
    *) warn "Usage: $0 [--max|--balanced|--battery|--status]"; exit 1 ;;
esac

# ─── 1. CPU governor + schedutil ──────────────────────────────────────────────
log "CPU governors (direct sysfs — kernel interface)"
for p in 0 4 7; do
    ws "/sys/devices/system/cpu/cpufreq/policy${p}/scaling_governor" "$CPU_GOV"
    [ "$CPU_GOV" = "schedutil" ] && \
        ws "/sys/devices/system/cpu/cpufreq/policy${p}/schedutil/rate_limit_us" "500"
done

# ─── 2. WALT scheduler ────────────────────────────────────────────────────────
log "WALT scheduler (proc/sys/kernel — standard Linux interface)"
printf "%s" "$SCHED_UP" > /proc/sys/kernel/sched_upmigrate   2>/dev/null && ok "sched_upmigrate = $SCHED_UP"   || warn "sched_upmigrate blocked"
printf "%s" "$SCHED_DN" > /proc/sys/kernel/sched_downmigrate 2>/dev/null && ok "sched_downmigrate = $SCHED_DN" || warn "sched_downmigrate blocked"
echo "$BOOST"            > /proc/sys/kernel/sched_boost       2>/dev/null && ok "sched_boost = $BOOST"          || warn "sched_boost blocked"
echo 1                   > /proc/sys/kernel/sched_walt_rotate_big_tasks 2>/dev/null && ok "walt_rotate_big_tasks = 1" || warn "skipped"

# ─── 3. VM (sysctl — standard Linux) ─────────────────────────────────────────
log "VM parameters (sysctl)"
sysctl -w vm.swappiness=$SWAP                2>/dev/null && ok "swappiness = $SWAP"
sysctl -w vm.dirty_ratio=$DIRTY             2>/dev/null && ok "dirty_ratio = $DIRTY"
sysctl -w vm.dirty_background_ratio=$DIRTY_BG 2>/dev/null && ok "dirty_background_ratio = $DIRTY_BG"
sysctl -w vm.dirty_expire_centisecs=1000    2>/dev/null
sysctl -w vm.dirty_writeback_centisecs=500  2>/dev/null
sysctl -w vm.vfs_cache_pressure=50         2>/dev/null && ok "vfs_cache_pressure = 50"
sysctl -w vm.page-cluster=0                2>/dev/null && ok "page-cluster = 0"

# ─── 4. Network (sysctl) ──────────────────────────────────────────────────────
log "Network buffers (sysctl)"
sysctl -w net.core.rmem_max=67108864        2>/dev/null && ok "rmem_max = 64MB"
sysctl -w net.core.wmem_max=67108864        2>/dev/null && ok "wmem_max = 64MB"
sysctl -w net.core.rmem_default=4194304     2>/dev/null
sysctl -w net.core.wmem_default=4194304     2>/dev/null
sysctl -w net.core.netdev_max_backlog=16384 2>/dev/null
sysctl -w net.ipv4.tcp_fastopen=3          2>/dev/null && ok "tcp_fastopen = 3"
sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null \
    && ok "TCP CC = BBR" \
    || { sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null && ok "TCP CC = cubic"; }

# ─── 5. I/O scheduler ────────────────────────────────────────────────────────
log "I/O scheduler — UFS 3.0 (sysfs block subsystem)"
for blk in sda sdb sdc sdd sde sdf; do
    [ -f "/sys/block/${blk}/queue/scheduler" ] || continue
    ws "/sys/block/${blk}/queue/scheduler"     "deadline"
    ws "/sys/block/${blk}/queue/read_ahead_kb" "512"
    ws "/sys/block/${blk}/queue/nr_requests"   "256"
    ws "/sys/block/${blk}/queue/add_random"    "0"
done

# ─── 6. GPU Adreno 640v2 ──────────────────────────────────────────────────────
log "GPU Adreno 640v2 (sysfs kgsl subsystem)"
GPU="/sys/class/kgsl/kgsl-3d0"
ws "${GPU}/devfreq/governor"  "$GPU_GOV"
ws "${GPU}/min_pwrlevel"      "$GPU_MIN"
ws "${GPU}/default_pwrlevel"  "$GPU_DEF"
ws "${GPU}/acd_enable_by_level" "1" 2>/dev/null || true

# ─── 7. Write native Linux config files INTO the Ubuntu chroot ────────────────
if [ -n "${UBUNTU_ROOT}" ]; then
    log "Writing native Linux config into Ubuntu chroot: ${UBUNTU_ROOT}"

    # /etc/sysctl.d/ — VM
    mkdir -p "${UBUNTU_ROOT}/etc/sysctl.d"
    cat > "${UBUNTU_ROOT}/etc/sysctl.d/99-perf-vm.conf" << EOF
# SM8150 VM tuning — mode: ${MODE}
vm.swappiness = ${SWAP}
vm.dirty_ratio = ${DIRTY}
vm.dirty_background_ratio = ${DIRTY_BG}
vm.dirty_expire_centisecs = 1000
vm.dirty_writeback_centisecs = 500
vm.vfs_cache_pressure = 50
vm.page-cluster = 0
EOF
    ok "chroot: /etc/sysctl.d/99-perf-vm.conf"

    # /etc/sysctl.d/ — Network
    cat > "${UBUNTU_ROOT}/etc/sysctl.d/99-perf-net.conf" << 'EOF'
# SM8150 network tuning
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_rmem = 4096 4194304 67108864
net.ipv4.tcp_wmem = 4096 4194304 67108864
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_congestion_control = cubic
EOF
    ok "chroot: /etc/sysctl.d/99-perf-net.conf"

    # /etc/udev/rules.d/ — I/O scheduler
    mkdir -p "${UBUNTU_ROOT}/etc/udev/rules.d"
    cat > "${UBUNTU_ROOT}/etc/udev/rules.d/60-io-scheduler.rules" << 'EOF'
# UFS 3.0 — deadline scheduler for lower latency (applied by udev at device registration)
ACTION=="add|change", KERNEL=="sd[a-f]", ATTR{queue/scheduler}="deadline"
ACTION=="add|change", KERNEL=="sd[a-f]", ATTR{queue/read_ahead_kb}="512"
ACTION=="add|change", KERNEL=="sd[a-f]", ATTR{queue/nr_requests}="256"
ACTION=="add|change", KERNEL=="sd[a-f]", ATTR{queue/add_random}="0"
EOF
    ok "chroot: /etc/udev/rules.d/60-io-scheduler.rules"

    ok "All native Linux config files written into chroot"
    echo "  → Run 'sudo sysctl -p /etc/sysctl.d/99-perf-vm.conf' after entering chroot as root"
fi

echo -e "\n${GREEN}${BOLD}Tuning applied — mode: ${MODE}${RESET}"
echo "  Sysfs writes: immediate (runtime)"
echo "  Config files: persistent via sysctl.d + udev (if UBUNTU_ROOT found)"
show_status
