#!/bin/bash
# cleanup.sh — safe system cleanup for OnePlus 7 Pro Ubuntu chroot
# Usage: cleanup [--deep]
#
# NOTE: sudo is NOT used here — the Ubuntu chroot runs without root capabilities
# (CapEff=0). apt and log cleanup are user-safe. Root-level log purging requires
# running from Termux with Magisk su.

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
info() { echo -e "  $1"; }

echo -e "${BOLD}Starting cleanup...${RESET}"

echo -e "\n${CYAN}${BOLD}1. APT cache cleanup${RESET}"
# apt autoremove/clean do not require root in some chroot setups; gracefully skip if not
if apt autoremove -y 2>/dev/null; then
    ok "apt autoremove"
else
    warn "apt autoremove skipped (no root — run from Termux: su -c 'apt autoremove -y')"
fi
apt autoclean 2>/dev/null && ok "apt autoclean" || warn "apt autoclean skipped (no root)"
apt clean 2>/dev/null && ok "apt clean" || warn "apt clean skipped (no root)"

echo -e "\n${CYAN}${BOLD}2. Pip cache${RESET}"
pip3 cache purge 2>/dev/null && ok "pip cache purged" || warn "pip3 cache purge skipped"

echo -e "\n${CYAN}${BOLD}3. npm cache${RESET}"
npm cache clean --force 2>/dev/null && ok "npm cache cleaned" || warn "npm cache clean skipped"

echo -e "\n${CYAN}${BOLD}4. Old log files (>7 days, user-accessible only)${RESET}"
# System logs in /var/log require root — skip silently if permission denied
find /var/log -name "*.gz" -mtime +7 -delete 2>/dev/null && ok "/var/log *.gz removed" || warn "/var/log cleanup skipped (no root)"
find /var/log -name "*.1"  -mtime +7 -delete 2>/dev/null
# journalctl vacuum — harmless if not root (just won't purge system journal)
journalctl --vacuum-time=7d 2>/dev/null && ok "journal vacuumed" || true

echo -e "\n${CYAN}${BOLD}5. Temp files${RESET}"
find /tmp -maxdepth 1 -mtime +1 -not -name "." -delete 2>/dev/null && ok "/tmp old files removed" || true

echo -e "\n${CYAN}${BOLD}6. Zsh compdump cache${RESET}"
find "$HOME" -maxdepth 1 -name ".zcompdump*" -not -newer "$HOME/.zshrc" -delete 2>/dev/null \
    && ok "zcompdump stale caches removed" || true

echo -e "\n${CYAN}${BOLD}7. Go build cache (user)${RESET}"
go clean -cache 2>/dev/null && ok "Go build cache cleared" || warn "go not found or failed"

echo -e "\n${CYAN}${BOLD}8. Cargo registry cache${RESET}"
# Keep installed binaries; only purge registry/source cache
if command -v cargo &>/dev/null; then
    CARGO_CACHE="${CARGO_HOME:-$HOME/.cargo}/registry/cache"
    [ -d "$CARGO_CACHE" ] && rm -rf "$CARGO_CACHE" && ok "Cargo registry cache cleared" || true
fi

if [ "${1:-}" = "--deep" ]; then
    echo -e "\n${CYAN}${BOLD}9. Docker cleanup (deep)${RESET}"
    docker system prune -f 2>/dev/null && ok "docker pruned" || warn "docker not running"
    docker volume prune -f 2>/dev/null && ok "docker volumes pruned" || true

    echo -e "\n${CYAN}${BOLD}10. Ollama — list models (remove manually with 'ollama rm <model>')${RESET}"
    info "Current models:"
    ollama list 2>/dev/null | tail -n +2 | while read -r line; do info "  $line"; done
    info "Remove unused: ollama rm <model-name>"

    echo -e "\n${CYAN}${BOLD}11. Node modules in workspace (older than 30 days)${RESET}"
    find "$HOME/workspace" -maxdepth 3 -name "node_modules" -mtime +30 -type d \
        -exec echo "  Found: {}" \; 2>/dev/null || true
    info "Run 'rm -rf <path>/node_modules' to free space"
fi

echo ""
df -h "$HOME" 2>/dev/null | tail -1 | awk '{printf "  Disk: %s used of %s (%s free)\n", $3, $2, $4}'
echo -e "\n${GREEN}${BOLD}Cleanup complete!${RESET}"
