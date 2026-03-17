#!/bin/bash
# post-install-setup.sh — Ubuntu 24.04.4 First Boot Configuration
# HP EliteBook 840 G9 — Run after Ubuntu installation is complete
# Usage: bash post-install-setup.sh
#
# What this does:
#   1. System update + essential packages
#   2. GRUB config (always show menu — no auto-boot)
#   3. Clock sync fix for dual boot (prevents Windows time drift)
#   4. Hardware packages (audio, GPU tools, power management)
#   5. UFW firewall
#   6. Timeshift system snapshots
#   7. os-prober (makes GRUB detect Windows)

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

log()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

echo -e "${BOLD}${CYAN}"
echo "=================================================="
echo "  SampleMind — Ubuntu 24.04.4 Post-Install Setup"
echo "  HP EliteBook 840 G9"
echo "=================================================="
echo -e "${NC}"

# ─── Root check ──────────────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    err "Do NOT run as root. Run as your normal user: bash post-install-setup.sh"
fi

# ─── Step 1: System Update ───────────────────────────────────────────────────
log "Step 1/7 — System update..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    build-essential git curl wget unzip zip \
    software-properties-common apt-transport-https ca-certificates \
    gnupg lsb-release nano vim htop btop ncdu tree jq \
    ubuntu-drivers-common
ok "System packages updated"

# ─── Step 2: GRUB Configuration (Always Show Menu) ───────────────────────────
log "Step 2/7 — Configuring GRUB (always show menu, no auto-boot)..."

# Install os-prober so GRUB detects Windows
sudo apt install -y os-prober
sudo sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub > /dev/null

# Set GRUB_TIMEOUT=-1 → always show menu (user's choice)
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=-1/'         /etc/default/grub
sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/'          /etc/default/grub

# Ensure menu is always visible (not hidden countdown)
if grep -q "^GRUB_TIMEOUT_STYLE" /etc/default/grub; then
    sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
else
    echo 'GRUB_TIMEOUT_STYLE=menu' | sudo tee -a /etc/default/grub > /dev/null
fi

sudo update-grub
ok "GRUB configured — always shows menu, never auto-boots"

# ─── Step 3: Dual Boot Clock Fix ─────────────────────────────────────────────
log "Step 3/7 — Fixing dual boot clock sync..."
# Ubuntu uses UTC hardware clock, Windows uses local time → causes clock drift
# This tells Ubuntu to use local time (matches Windows behavior)
sudo timedatectl set-local-rtc 1 --adjust-system-clock
timedatectl status | grep -E "Local time|RTC|NTP"
ok "Clock sync fixed (RTC in local time)"

# ─── Step 4: Hardware Packages (EliteBook 840 G9) ────────────────────────────
log "Step 4/7 — Installing EliteBook 840 G9 hardware packages..."

sudo apt install -y \
    linux-headers-$(uname -r) \
    firmware-sof-signed \
    alsa-ucm-conf \
    pipewire \
    pipewire-pulse \
    wireplumber \
    libspa-0.2-bluetooth \
    hplip \
    thermald \
    tlp \
    tlp-rdw \
    powertop \
    acpi \
    rfkill \
    intel-gpu-tools \
    vainfo \
    mesa-utils \
    fprintd \
    libpam-fprintd

# Enable power management
sudo systemctl enable thermald tlp 2>/dev/null || warn "thermald/tlp not installed"
sudo systemctl start  thermald tlp 2>/dev/null || true

ok "Hardware packages installed"

# Quick GPU check
log "Verifying Intel Iris Xe driver..."
if command -v glxinfo &>/dev/null; then
    GPU_RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs || echo "unknown")
    ok "GPU: $GPU_RENDERER"
else
    warn "glxinfo not available yet — log out and back in"
fi

# ─── Step 5: UFW Firewall ────────────────────────────────────────────────────
log "Step 5/7 — Configuring UFW firewall..."
sudo ufw allow ssh
sudo ufw allow 3000/tcp    # Next.js dev
sudo ufw allow 8000/tcp    # FastAPI
sudo ufw allow 8001/tcp    # ChromaDB
sudo ufw allow 8080/tcp    # Misc services
sudo ufw allow 11434/tcp   # Ollama
sudo ufw --force enable
sudo ufw status
ok "UFW enabled"

# ─── Step 6: Timeshift Snapshots ─────────────────────────────────────────────
log "Step 6/7 — Installing Timeshift for system snapshots..."
sudo apt install -y timeshift
ok "Timeshift installed — run 'sudo timeshift-gtk' to configure snapshots"
warn "Recommended: Create a snapshot NOW before installing SampleMind stack"

# ─── Step 7: Secure Boot Verification ────────────────────────────────────────
log "Step 7/7 — Verifying Secure Boot status..."
if command -v mokutil &>/dev/null; then
    SECBOOT=$(mokutil --sb-state 2>/dev/null || echo "unknown")
    ok "Secure Boot: $SECBOOT"
    if echo "$SECBOOT" | grep -qi "enabled"; then
        ok "Ubuntu running WITH Secure Boot — SHIM bootloader active"
    fi
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}=================================================="
echo "  Post-install complete!"
echo "==================================================${NC}"
echo ""
echo -e "${CYAN}GPU check:${NC}     glxinfo | grep renderer"
echo -e "${CYAN}Monitor GPU:${NC}   sudo intel_gpu_top"
echo -e "${CYAN}Secure Boot:${NC}   mokutil --sb-state"
echo -e "${CYAN}Audio fix:${NC}     systemctl --user restart pipewire pipewire-pulse"
echo -e "${CYAN}Fingerprint:${NC}   fprintd-enroll"
echo -e "${CYAN}Snapshot:${NC}      sudo timeshift-gtk"
echo ""
echo -e "${YELLOW}Next step: Follow SAMPLEMIND-DEV-SETUP.md to install the development environment${NC}"
echo ""
