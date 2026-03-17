#!/bin/bash
# upgrade-stack.sh — Upgrade all dev components to latest versions
# Go, Rust, Node, Python tools, Docker, Helm, k9s, Terraform, Ollama
# Usage: bash upgrade-stack.sh [--check|--all|--go|--rust|--tools]

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
info() { echo -e "  $1"; }

MODE="${1:---all}"

# ─── Version check ────────────────────────────────────────────────────────────
check_versions() {
    log "Current versions"
    info "Go:        $(go version 2>/dev/null)"
    info "Rust:      $(rustc --version 2>/dev/null)"
    info "Cargo:     $(cargo --version 2>/dev/null)"
    info "Node:      $(node --version 2>/dev/null)"
    info "Python:    $(python3 --version 2>/dev/null)"
    info "Ollama:    $(ollama --version 2>/dev/null)"
    info "Docker:    $(docker --version 2>/dev/null)"
    info "kubectl:   $(kubectl version --client -o json 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)[\"clientVersion\"][\"gitVersion\"])' 2>/dev/null)"
    info "Helm:      $(helm version --short 2>/dev/null)"
    info "Terraform: $(terraform version 2>/dev/null | head -1)"
    info "k9s:       $(k9s version 2>/dev/null | head -1)"
    info "nvim:      $(nvim --version 2>/dev/null | head -1)"
    info "tmux:      $(tmux -V 2>/dev/null)"
    info "lazygit:   $(lazygit --version 2>/dev/null | head -1)"
}

if [ "$MODE" = "--check" ]; then check_versions; exit 0; fi

# ─── Go ───────────────────────────────────────────────────────────────────────
upgrade_go() {
    log "Upgrading Go"
    LATEST=$(curl -fsSL "https://go.dev/VERSION?m=text" 2>/dev/null | head -1)
    CURRENT=$(go version 2>/dev/null | awk '{print $3}')
    info "Current: $CURRENT | Latest: $LATEST"
    if [ "$CURRENT" = "$LATEST" ]; then ok "Go already up to date"; return; fi
    local tarball="/tmp/${LATEST}.linux-arm64.tar.gz"
    curl -fsSL "https://go.dev/dl/${LATEST}.linux-arm64.tar.gz" -o "$tarball"
    rm -rf ~/.local/lib/go
    tar -xzf "$tarball" -C ~/.local/lib/
    ok "Go upgraded: $(~/.local/lib/go/bin/go version)"
    rm -f "$tarball"
}

# ─── Rust ─────────────────────────────────────────────────────────────────────
upgrade_rust() {
    log "Upgrading Rust (rustup)"
    rustup update stable 2>&1 | tail -3
    ok "Rust: $(~/.cargo/bin/rustc --version 2>/dev/null)"
    # Install useful cargo tools if missing
    for tool in cargo-edit cargo-watch; do
        command -v "${tool#cargo-}" &>/dev/null || cargo install "$tool" --quiet 2>/dev/null && ok "Installed $tool" || true
    done
}

# ─── Node via NVM ─────────────────────────────────────────────────────────────
upgrade_node() {
    log "Node.js (via nvm)"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm install --lts 2>&1 | tail -3
    nvm alias default lts/* 2>/dev/null
    ok "Node: $(node --version) | npm: $(npm --version)"
    npm update -g 2>/dev/null | tail -3
}

# ─── Python pip tools ─────────────────────────────────────────────────────────
upgrade_python() {
    log "Python pip tools"
    pip3 install --upgrade pip setuptools wheel 2>&1 | tail -3
    pip3 install --upgrade \
        anthropic openai langchain langchain-community \
        fastapi uvicorn httpx \
        jupyterlab huggingface_hub \
        ruff black isort mypy \
        rich typer click \
        2>&1 | tail -5
    ok "Core Python packages upgraded"
}

# ─── Dev tools via apt ────────────────────────────────────────────────────────
upgrade_apt_tools() {
    log "System packages (apt)"
    # NOTE: sudo is not available in the Ubuntu chroot (CapEff=0).
    # This function is only effective when run as root (e.g. via Termux su + root-enter.sh)
    if [ "$(id -u)" = "0" ]; then
        apt update -qq 2>&1 | tail -2
        apt upgrade -y 2>&1 | tail -5
        ok "System packages upgraded"
    else
        warn "apt upgrade skipped — no root in chroot"
        warn "To upgrade system packages, run from Termux:"
        warn "  su -c \"bash /storage/emulated/0/dev/scripts/android/root-enter.sh\""
        warn "  then inside root chroot: apt update && apt upgrade -y"
    fi
}

# ─── Helm ─────────────────────────────────────────────────────────────────────
upgrade_helm() {
    log "Helm"
    LATEST=$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
    CURRENT=$(helm version --short 2>/dev/null | cut -d+ -f1 | tr -d 'v')
    info "Current: v$CURRENT | Latest: $LATEST"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 2>&1 | tail -3
    ok "Helm: $(helm version --short)"
}

# ─── k9s ──────────────────────────────────────────────────────────────────────
upgrade_k9s() {
    log "k9s"
    LATEST=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
    info "Latest: $LATEST"
    local url="https://github.com/derailed/k9s/releases/download/${LATEST}/k9s_Linux_arm64.tar.gz"
    mkdir -p ~/.local/bin
    curl -fsSL "$url" | tar -xzf - -C ~/.local/bin k9s 2>/dev/null
    ok "k9s: $(~/.local/bin/k9s version 2>/dev/null | head -1)"
}

# ─── lazygit ──────────────────────────────────────────────────────────────────
upgrade_lazygit() {
    log "lazygit"
    LATEST=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")
    info "Latest: $LATEST"
    local url="https://github.com/jesseduffield/lazygit/releases/download/v${LATEST}/lazygit_${LATEST}_Linux_arm64.tar.gz"
    mkdir -p ~/.local/bin
    curl -fsSL "$url" | tar -xzf - -C ~/.local/bin lazygit 2>/dev/null
    ok "lazygit: $(~/.local/bin/lazygit --version 2>/dev/null | head -1)"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
check_versions

case "$MODE" in
    --all)
        upgrade_go
        upgrade_rust
        upgrade_python
        ;;
    --go)    upgrade_go ;;
    --rust)  upgrade_rust ;;
    --node)  upgrade_node ;;
    --tools) upgrade_apt_tools; upgrade_helm; upgrade_k9s; upgrade_lazygit ;;
    --python) upgrade_python ;;
esac

echo -e "\n${GREEN}${BOLD}Upgrade complete.${RESET}"
check_versions
