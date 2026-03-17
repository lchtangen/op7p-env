#!/bin/bash
# bootstrap.sh — Complete environment bootstrap for Ubuntu on OnePlus 7 Pro
# Run this once on a fresh Ubuntu chroot to install and configure everything.
# Usage: bash bootstrap.sh [--full|--dev|--ai|--k8s|--check]
#
# Sections:
#   --dev    Languages: Go, Rust, Node, Python + dev tools
#   --ai     AI stack: Ollama, models, Python AI packages
#   --k8s    Kubernetes: kubectl, Helm, k9s, Terraform
#   --full   All of the above (default)

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

MODE="${1:---full}"
ARCH="arm64"
USER_BIN="$HOME/.local/bin"
LOG="/tmp/bootstrap.log"

log()   { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}" | tee -a "$LOG"; }
ok()    { echo -e "${GREEN}  ✓ $1${RESET}" | tee -a "$LOG"; }
warn()  { echo -e "${YELLOW}  ⚠ $1${RESET}" | tee -a "$LOG"; }
err()   { echo -e "${RED}  ✗ $1${RESET}" | tee -a "$LOG"; }
info()  { echo -e "  $1" | tee -a "$LOG"; }
skip()  { echo -e "${YELLOW}  → $1 (already installed — skipping)${RESET}"; }

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║  Bootstrap — Ubuntu 24.04 ARM64 (OnePlus 7 Pro) ║"
echo "  ║  Mode: ${MODE}                                    "
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${RESET}"

mkdir -p "$USER_BIN" "$HOME/.local/lib" "$HOME/.config" 2>/dev/null || true
mkdir -p "$HOME/ai/agents" "$HOME/ai/prompts" "$HOME/ai/notebooks" "$HOME/ai/workflows"
mkdir -p "$HOME/dev/scripts" "$HOME/projects" "$HOME/workspace"
mkdir -p "$HOME/docs" "$HOME/recovery" "$HOME/backups/dotfiles"

# ─── System packages ────────────────────────────────────────────────────────
install_apt_packages() {
    log "System packages (apt)"
    sudo apt update -qq 2>&1 | tail -2
    sudo apt install -y \
        build-essential gcc g++ make cmake \
        git git-lfs curl wget unzip zip \
        jq yq bc \
        zsh zsh-autosuggestions zsh-syntax-highlighting \
        tmux neovim \
        eza bat fd-find ripgrep \
        btop htop duf ncdu \
        redis-server \
        docker.io \
        python3 python3-pip python3-venv python3-dev \
        nodejs npm \
        ssh ca-certificates \
        2>&1 | tail -10
    ok "System packages installed"

    # Fix Ubuntu naming (batcat → bat, fdfind → fd)
    mkdir -p "$USER_BIN"
    [ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$USER_BIN/bat" && ok "bat symlink created"
    [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$USER_BIN/fd" && ok "fd symlink created"
}

# ─── Go ──────────────────────────────────────────────────────────────────────
install_go() {
    if command -v go &>/dev/null; then
        skip "Go ($(go version | awk '{print $3}'))"
        return
    fi
    log "Installing Go (latest ARM64)"
    LATEST=$(curl -fsSL "https://go.dev/VERSION?m=text" 2>/dev/null | head -1)
    local tarball="/tmp/${LATEST}.linux-${ARCH}.tar.gz"
    curl -fsSL "https://go.dev/dl/${LATEST}.linux-${ARCH}.tar.gz" -o "$tarball"
    mkdir -p "$HOME/.local/lib"
    tar -xzf "$tarball" -C "$HOME/.local/lib/"
    ln -sfn "$HOME/.local/lib/go/bin/go" "$USER_BIN/go"
    ln -sfn "$HOME/.local/lib/go/bin/gofmt" "$USER_BIN/gofmt"
    rm -f "$tarball"
    ok "Go: $(~/.local/lib/go/bin/go version)"
}

# ─── Rust ────────────────────────────────────────────────────────────────────
install_rust() {
    if command -v rustc &>/dev/null; then
        skip "Rust ($(rustc --version))"
        return
    fi
    log "Installing Rust (rustup)"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path 2>&1 | tail -3
    ok "Rust: $(~/.cargo/bin/rustc --version 2>/dev/null)"
}

# ─── Node via NVM ────────────────────────────────────────────────────────────
install_node() {
    if [ -d "$HOME/.nvm" ]; then
        skip "nvm (already installed)"
        return
    fi
    log "Installing Node.js via nvm"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash 2>&1 | tail -3
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm install --lts 2>&1 | tail -3
    nvm alias default lts/*
    ok "Node: $(node --version 2>/dev/null)"
}

# ─── Python packages ─────────────────────────────────────────────────────────
install_python_packages() {
    log "Python AI/dev packages"
    pip3 install --upgrade pip setuptools wheel 2>&1 | tail -2
    pip3 install --upgrade \
        anthropic openai \
        langchain langchain-community langchain-ollama langchain-core \
        litellm \
        fastapi uvicorn httpx \
        jupyterlab \
        huggingface_hub \
        ollama \
        ruff black isort mypy \
        rich typer click \
        2>&1 | tail -5
    ok "Python packages installed"
}

# ─── Ollama ──────────────────────────────────────────────────────────────────
install_ollama() {
    if command -v ollama &>/dev/null; then
        skip "Ollama ($(ollama --version 2>/dev/null))"
        return
    fi
    log "Installing Ollama"
    curl -fsSL https://ollama.com/install.sh | sh 2>&1 | tail -5
    ok "Ollama: $(ollama --version 2>/dev/null)"
}

pull_ollama_models() {
    log "Pulling Ollama models (essential set)"
    info "smollm2:135m (270MB)..."
    ollama pull smollm2:135m 2>&1 | tail -2

    info "llama3.2:3b (2GB)..."
    ollama pull llama3.2:3b 2>&1 | tail -2

    info "qwen2.5-coder:7b (4.7GB — primary code model)..."
    ollama pull qwen2.5-coder:7b 2>&1 | tail -2
    ok "Models installed"
}

# ─── kubectl ─────────────────────────────────────────────────────────────────
install_kubectl() {
    if command -v kubectl &>/dev/null; then
        skip "kubectl ($(kubectl version --client --short 2>/dev/null))"
        return
    fi
    log "Installing kubectl"
    LATEST=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/${LATEST}/bin/linux/${ARCH}/kubectl" -o /tmp/kubectl
    install -m 0755 /tmp/kubectl "$USER_BIN/kubectl"
    rm -f /tmp/kubectl
    ok "kubectl: $("$USER_BIN/kubectl" version --client --short 2>/dev/null)"
}

# ─── Helm ─────────────────────────────────────────────────────────────────────
install_helm() {
    if command -v helm &>/dev/null; then
        skip "Helm ($(helm version --short 2>/dev/null))"
        return
    fi
    log "Installing Helm"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 2>&1 | tail -3
    ok "Helm: $(helm version --short 2>/dev/null)"
}

# ─── k9s ─────────────────────────────────────────────────────────────────────
install_k9s() {
    if command -v k9s &>/dev/null; then
        skip "k9s"
        return
    fi
    log "Installing k9s"
    LATEST=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
    curl -fsSL "https://github.com/derailed/k9s/releases/download/${LATEST}/k9s_Linux_arm64.tar.gz" \
        | tar -xzf - -C "$USER_BIN" k9s
    ok "k9s: $("$USER_BIN/k9s" version 2>/dev/null | head -1)"
}

# ─── Terraform ───────────────────────────────────────────────────────────────
install_terraform() {
    if command -v terraform &>/dev/null; then
        skip "Terraform ($(terraform version 2>/dev/null | head -1))"
        return
    fi
    log "Installing Terraform"
    LATEST=$(curl -fsSL https://api.github.com/repos/hashicorp/terraform/releases/latest 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")
    curl -fsSL "https://releases.hashicorp.com/terraform/${LATEST}/terraform_${LATEST}_linux_arm64.zip" \
        -o /tmp/terraform.zip
    unzip -o /tmp/terraform.zip -d /tmp/tf-bin >/dev/null
    install -m 0755 /tmp/tf-bin/terraform "$USER_BIN/terraform"
    rm -rf /tmp/terraform.zip /tmp/tf-bin
    ok "Terraform: $(terraform version 2>/dev/null | head -1)"
}

# ─── lazygit ─────────────────────────────────────────────────────────────────
install_lazygit() {
    if command -v lazygit &>/dev/null; then
        skip "lazygit"
        return
    fi
    log "Installing lazygit"
    LATEST=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LATEST}/lazygit_${LATEST}_Linux_arm64.tar.gz" \
        | tar -xzf - -C "$USER_BIN" lazygit
    ok "lazygit installed"
}

# ─── Check mode ──────────────────────────────────────────────────────────────
check_all() {
    log "Installed components"
    printf "  %-15s %s\n" "go" "$(go version 2>/dev/null | awk '{print $3}' || echo 'not installed')"
    printf "  %-15s %s\n" "rustc" "$(rustc --version 2>/dev/null || echo 'not installed')"
    printf "  %-15s %s\n" "node" "$(node --version 2>/dev/null || echo 'not installed')"
    printf "  %-15s %s\n" "python3" "$(python3 --version 2>/dev/null || echo 'not installed')"
    printf "  %-15s %s\n" "ollama" "$(ollama --version 2>/dev/null || echo 'not installed')"
    printf "  %-15s %s\n" "docker" "$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo 'not installed')"
    printf "  %-15s %s\n" "kubectl" "$(kubectl version --client --short 2>/dev/null || echo 'not installed')"
    printf "  %-15s %s\n" "helm" "$(helm version --short 2>/dev/null || echo 'not installed')"
    printf "  %-15s %s\n" "terraform" "$(terraform version 2>/dev/null | head -1 || echo 'not installed')"
    printf "  %-15s %s\n" "k9s" "$(k9s version 2>/dev/null | head -1 || echo 'not installed')"
    printf "  %-15s %s\n" "nvim" "$(nvim --version 2>/dev/null | head -1 || echo 'not installed')"
    printf "  %-15s %s\n" "tmux" "$(tmux -V 2>/dev/null || echo 'not installed')"
    printf "  %-15s %s\n" "lazygit" "$(lazygit --version 2>/dev/null | head -1 || echo 'not installed')"
}

# ─── Main ────────────────────────────────────────────────────────────────────
case "$MODE" in
    --check)
        check_all
        ;;
    --dev)
        install_apt_packages
        install_go
        install_rust
        install_node
        install_python_packages
        install_lazygit
        ;;
    --ai)
        install_ollama
        pull_ollama_models
        install_python_packages
        ;;
    --k8s)
        install_kubectl
        install_helm
        install_k9s
        install_terraform
        ;;
    --full)
        install_apt_packages
        install_go
        install_rust
        install_node
        install_python_packages
        install_ollama
        pull_ollama_models
        install_kubectl
        install_helm
        install_k9s
        install_terraform
        install_lazygit
        check_all
        ;;
    *)
        info "Usage: bootstrap.sh [--full|--dev|--ai|--k8s|--check]"
        exit 1
        ;;
esac

echo -e "\n${GREEN}${BOLD}Bootstrap complete! Log: $LOG${RESET}\n"
echo "  Next steps:"
echo "  1. Restart shell: exec zsh"
echo "  2. Apply performance tuning (from Termux):"
echo "     su -c 'bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced'"
echo "  3. Start AI: bash ~/dev/scripts/linux/ai-stack.sh --start"
