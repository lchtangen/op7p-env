#!/bin/bash
# termux-setup.sh — Configure Termux environment for OnePlus 7 Pro development
# Run from Termux (NOT from Ubuntu chroot): bash termux-setup.sh
# Sets up: storage, essential packages, SSH server, zsh, ubuntu chroot launcher
#
# Usage: bash termux-setup.sh [--full|--minimal|--ssh|--chroot-launcher]

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

MODE="${1:---full}"
log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
err()  { echo -e "${RED}  ✗ $1${RESET}"; }
info() { echo -e "  $1"; }

# Detect Termux vs chroot
if [ -d /data/data/com.termux ] || [ -n "${TERMUX_VERSION:-}" ]; then
    IN_TERMUX=true
else
    IN_TERMUX=false
    warn "This script is designed for Termux, not Ubuntu chroot."
    warn "Some features may not work correctly."
fi

setup_storage() {
    log "Setting up Termux storage access"
    termux-setup-storage 2>/dev/null || warn "Run 'termux-setup-storage' manually if needed"
    ok "Storage setup initiated (allow permission in popup)"
}

install_packages() {
    log "Updating Termux packages"
    pkg update -y 2>&1 | tail -3
    pkg upgrade -y 2>&1 | tail -3

    log "Installing essential packages"
    pkg install -y \
        git curl wget zip unzip \
        openssh \
        zsh \
        proot-distro \
        termux-api \
        python \
        nodejs \
        nano vim \
        htop \
        2>&1 | tail -5
    ok "Essential packages installed"
}

setup_zsh() {
    log "Configuring zsh in Termux"
    chsh -s zsh 2>/dev/null || warn "Could not set default shell — run: chsh -s zsh"

    # Basic Termux zshrc additions (saved to .zshrc.d/termux.zsh and sourced from .zshrc)
    mkdir -p ~/.zshrc.d
    cat > ~/.zshrc.d/termux.zsh << 'EOF'
# Termux additions — OnePlus 7 Pro
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias ub='proot-distro login ubuntu'      # enter Ubuntu chroot
alias ub-root='proot-distro login ubuntu --user root'
alias perf-tune='su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh"'
alias perf-status='bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --status'
alias root-chroot='bash /storage/emulated/0/dev/scripts/android/root-enter.sh'

# Quick Magisk root commands
alias root='su'
alias as-root='su -c'

echo "Termux — OnePlus 7 Pro | 'ub' to enter Ubuntu"
EOF

    # Append source line to .zshrc if not already there
    if ! grep -q "zshrc.d/termux.zsh" ~/.zshrc 2>/dev/null; then
        echo '[[ -f ~/.zshrc.d/termux.zsh ]] && source ~/.zshrc.d/termux.zsh' >> ~/.zshrc
    fi

    ok "~/.zshrc.d/termux.zsh written and sourced from ~/.zshrc"
    info "  Reload with: source ~/.zshrc"
}

setup_ssh() {
    log "Configuring SSH server in Termux"

    # Generate SSH host keys if needed
    [ -f ~/.ssh/sshd_ed25519 ] || ssh-keygen -A 2>/dev/null || true

    # Set a password (required for SSH)
    warn "Set Termux password for SSH (used with ssh user@device-ip -p 8022):"
    passwd 2>/dev/null || warn "Set password with: passwd"

    # Create SSH start script
    mkdir -p ~/.local/bin
    cat > ~/.local/bin/sshd-start << 'EOF'
#!/bin/bash
# Start SSH in Termux on port 8022
sshd -p 8022
echo "SSH started on port 8022"
echo "Connect: ssh $(whoami)@$(ip route get 1 | awk '{print $7; exit}') -p 8022"
EOF
    chmod +x ~/.local/bin/sshd-start
    ok "SSH configured — run 'sshd-start' to start"
    info "  Connect from PC: ssh user@device-ip -p 8022"
    info "  Or via ADB tunnel: adb forward tcp:8022 tcp:8022"
}

setup_ubuntu_launcher() {
    log "Creating Ubuntu chroot launchers"
    mkdir -p ~/.local/bin

    # Detect Ubuntu chroot path (proot-distro or manual)
    UBUNTU_PATH=""
    for p in \
        "$HOME/../usr/var/lib/proot-distro/installed-rootfs/ubuntu" \
        "/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu" \
        "/data/local/ubuntu"; do
        [ -d "${p}/usr" ] && UBUNTU_PATH="$p" && break
    done

    # User launcher (proot-distro)
    cat > ~/.local/bin/ubuntu << 'LAUNCHER'
#!/bin/bash
exec proot-distro login ubuntu -- "$@"
LAUNCHER
    chmod +x ~/.local/bin/ubuntu

    # Root launcher (Magisk su + chroot)
    cat > ~/.local/bin/ubuntu-root << 'LAUNCHER'
#!/bin/bash
exec su -c "bash /storage/emulated/0/dev/scripts/android/root-enter.sh"
LAUNCHER
    chmod +x ~/.local/bin/ubuntu-root

    ok "Launchers created:"
    info "  ubuntu       — enter Ubuntu as user (proot-distro)"
    info "  ubuntu-root  — enter Ubuntu as root (Magisk su)"
}

apply_termux_properties() {
    log "Configuring Termux terminal properties"
    mkdir -p ~/.termux
    cat > ~/.termux/termux.properties << 'EOF'
# Termux properties — OnePlus 7 Pro
extra-keys = [['ESC','TAB','CTRL','ALT','|','/','UP','DOWN'],['F1','F2','F3','F4','F5','F6','LEFT','RIGHT']]
bell-character=ignore
terminal-margin-horizontal=3
terminal-margin-vertical=3
EOF
    termux-reload-settings 2>/dev/null || true
    ok "Termux properties applied"
}

print_summary() {
    log "Setup Summary"
    info ""
    info "  ubuntu           Enter Ubuntu chroot (user)"
    info "  ubuntu-root      Enter Ubuntu chroot (root via Magisk)"
    info "  sshd-start       Start SSH server on port 8022"
    info "  perf-tune        Apply SM8150 performance tuning (root)"
    info "  perf-status      Show current performance state"
    info ""
    info "  su               Magisk root shell"
    info "  su -c 'cmd'      Run command as root"
    info ""
    info "  Reload aliases: source ~/.zshrc"
}

case "$MODE" in
    --full)
        setup_storage
        install_packages
        setup_zsh
        setup_ssh
        setup_ubuntu_launcher
        apply_termux_properties
        print_summary
        ;;
    --minimal)
        install_packages
        setup_ubuntu_launcher
        ;;
    --ssh)
        setup_ssh
        ;;
    --chroot-launcher)
        setup_ubuntu_launcher
        ;;
    *)
        info "Usage: termux-setup.sh [--full|--minimal|--ssh|--chroot-launcher]"
        exit 1
        ;;
esac
