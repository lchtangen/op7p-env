#!/bin/bash
# docker-optimize.sh — Docker daemon optimization for OnePlus 7 Pro
# Switches storage from VFS (slow) to overlay2, tunes for ARM64/12GB RAM
# Run as root: sudo bash docker-optimize.sh

set -euo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

[ "$(id -u)" != "0" ] && echo -e "${RED}Run as root${RESET}" && exit 1

log() { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()  { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn(){ echo -e "${YELLOW}  ⚠ $1${RESET}"; }

log "Docker daemon optimization"

# Check current storage driver
CURRENT_DRIVER=$(docker info 2>/dev/null | grep "Storage Driver" | awk '{print $3}' || echo "unknown")
echo "  Current storage driver: $CURRENT_DRIVER"

# Check kernel overlay2 support
if grep -q overlay /proc/filesystems 2>/dev/null; then
    ok "overlayfs supported by kernel"
else
    warn "overlayfs not in /proc/filesystems — keeping current driver"
fi

# Write optimized daemon.json
DAEMON_JSON=/etc/docker/daemon.json
mkdir -p /etc/docker

cat > "$DAEMON_JSON" << 'EOF'
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  },
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 10,
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "builder": {
    "gc": {
      "enabled": true,
      "policy": [
        { "keepStorage": "2GB", "all": true }
      ]
    }
  }
}
EOF

ok "daemon.json written: overlay2 + BuildKit + log rotation"

# Warn about data migration if switching from vfs
if [ "$CURRENT_DRIVER" = "vfs" ]; then
    warn "Switching from VFS → overlay2 requires container/image migration"
    warn "Existing containers will NOT be visible after switch"
    warn "To migrate: docker save <image> > backup.tar before restarting"
    echo ""
    echo "  Images to save first:"
    docker images --format "  {{.Repository}}:{{.Tag}} ({{.Size}})" 2>/dev/null
fi

log "Apply now? This restarts Docker."
read -rp "  Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" = "yes" ]; then
    pkill dockerd 2>/dev/null || true
    sleep 2
    mount -t cgroup2 none /sys/fs/cgroup 2>/dev/null || true
    dockerd --config-file /etc/docker/daemon.json > /var/log/dockerd.log 2>&1 &
    sleep 3
    docker info 2>/dev/null | grep "Storage Driver\|Logging Driver"
    ok "Docker restarted with new config"
else
    warn "Changes saved to $DAEMON_JSON — restart Docker to apply"
fi
