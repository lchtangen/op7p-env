#!/bin/bash
# env-check.sh — Validate the OnePlus 7 Pro development environment
# Checks all installed tools, services, aliases, and config files
# Usage: env-check [--full|--tools|--services|--ai|--fix-hints]

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

log()   { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()    { echo -e "${GREEN}  ✓ ${BOLD}$1${RESET}  ${2:-}"; }
warn()  { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
fail()  { echo -e "${RED}  ✗ $1${RESET}"; ((FAIL_COUNT++)) || true; }
info()  { echo -e "  $1"; }

FAIL_COUNT=0
MODE="${1:---full}"

# ─── Tools ────────────────────────────────────────────────────────────────────
check_tools() {
    log "Language Runtimes"

    _check_tool() {
        local name="$1" cmd="$2" min_ver="${3:-}"
        if command -v "$cmd" &>/dev/null; then
            local ver
            ver=$("$cmd" --version 2>/dev/null | head -1 | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1 || echo "?")
            ok "$name" "($ver)"
        else
            fail "$name — not found (cmd: $cmd)"
        fi
    }

    _check_tool "Go"        "go"       "1.26"
    _check_tool "Rust"      "rustc"    "1.94"
    _check_tool "Cargo"     "cargo"    ""
    _check_tool "Node.js"   "node"     "24"
    _check_tool "npm"       "npm"      ""
    _check_tool "Python3"   "python3"  "3.12"
    _check_tool "pip3"      "pip3"     ""

    log "Dev Tools"
    _check_tool "Git"       "git"      ""
    _check_tool "GitHub CLI" "gh"      ""
    _check_tool "Neovim"    "nvim"     "0.11"
    _check_tool "tmux"      "tmux"     "3.4"
    _check_tool "lazygit"   "lazygit"  ""
    _check_tool "Docker"    "docker"   "29"
    _check_tool "kubectl"   "kubectl"  ""
    _check_tool "Helm"      "helm"     ""
    _check_tool "Terraform" "terraform" ""
    _check_tool "k9s"       "k9s"      ""
    _check_tool "Claude CLI" "claude"  ""

    log "Modern CLI Tools"
    _check_tool "eza (ls)"  "eza"      ""
    _check_tool "bat (cat)" "bat"      ""
    _check_tool "fd (find)" "fd"       ""
    _check_tool "rg (grep)" "rg"       ""
    _check_tool "btop (top)" "btop"    ""
    _check_tool "duf (df)"  "duf"      ""
    _check_tool "jq"        "jq"       ""
    _check_tool "fzf"       "fzf"      ""
    _check_tool "zoxide"    "zoxide"   ""
}

# ─── Services ─────────────────────────────────────────────────────────────────
check_services() {
    log "Services"
    # Ollama
    if curl -s --max-time 2 http://127.0.0.1:11434 > /dev/null 2>&1; then
        ok "Ollama" "(running on :11434)"
        MODEL_COUNT=$(ollama list 2>/dev/null | tail -n +2 | wc -l)
        info "  Models installed: $MODEL_COUNT"
        ollama list 2>/dev/null | tail -n +2 | sed 's/^/    /'
    else
        warn "Ollama not running — start: ollama serve &"
    fi

    # Redis
    if redis-cli ping > /dev/null 2>&1; then
        ok "Redis" "(running on :6379)"
    else
        warn "Redis not running — start: redis-server --daemonize yes"
    fi

    # Docker
    if docker info > /dev/null 2>&1; then
        DRIVER=$(docker info 2>/dev/null | grep "Storage Driver" | awk '{print $3}')
        ok "Docker" "(running, driver: $DRIVER)"
        [ "$DRIVER" = "vfs" ] && warn "Docker using VFS — switch to overlay2 for performance (requires root)"
    else
        warn "Docker not running — start: dockerd &"
    fi

    # VNC
    if pgrep -x "Xvnc\|Xtigervnc" > /dev/null 2>&1; then
        ok "VNC" "(running on :5901)"
    else
        info "VNC stopped (start with: vnc1080)"
    fi
}

# ─── AI environment ───────────────────────────────────────────────────────────
check_ai() {
    log "AI / Ollama"
    command -v ollama &>/dev/null && ok "ollama CLI" "($(ollama --version 2>/dev/null))" || fail "ollama not found"

    # Check OLLAMA env
    OLLAMA_ENV="$HOME/.config/ollama/env"
    [ -f "$OLLAMA_ENV" ] && ok "ollama env config" "($OLLAMA_ENV)" || warn "~/.config/ollama/env not found — run: ollama-config.sh --apply"

    # Check Python AI libs
    log "Python AI Libraries"
    for lib in anthropic openai langchain fastapi uvicorn jupyterlab huggingface_hub; do
        python3 -c "import ${lib//-/_}" 2>/dev/null \
            && ok "$lib" \
            || warn "$lib not installed (pip3 install $lib)"
    done

    # Check AI agent scripts
    log "AI Agents"
    AI_HOME="${AI_HOME:-$HOME/ai}"
    for agent in ai-chat ai-review ai-explain ai-commit ai-fix; do
        SCRIPT="$AI_HOME/agents/${agent}.sh"
        [ -f "$SCRIPT" ] && ok "$agent" "($SCRIPT)" || warn "$agent not found ($SCRIPT)"
    done

    # Check prompts
    log "Prompt Library"
    PROMPTS_DIR="$AI_HOME/prompts"
    if [ -d "$PROMPTS_DIR" ]; then
        PROMPT_COUNT=$(find "$PROMPTS_DIR" -name "*.md" ! -name "README.md" | wc -l)
        ok "Prompts" "($PROMPT_COUNT prompt files in $PROMPTS_DIR)"
    else
        warn "Prompts directory not found: $PROMPTS_DIR"
    fi
}

# ─── Config files ─────────────────────────────────────────────────────────────
check_config() {
    log "Shell Config"
    [ -f "$HOME/.zshrc" ]          && ok "~/.zshrc"          || fail "~/.zshrc missing"
    [ -f "/etc/zsh/zshenv" ]       && ok "/etc/zsh/zshenv"   || warn "/etc/zsh/zshenv missing"
    [ -f "/etc/zsh/zshrc.local" ]  && ok "/etc/zsh/zshrc.local" || warn "/etc/zsh/zshrc.local missing"

    log "Neovim Config"
    [ -f "$HOME/.config/nvim/init.lua" ] && ok "~/.config/nvim/init.lua" || warn "Neovim config missing"

    log "tmux Config"
    [ -f "$HOME/.config/tmux/tmux.conf" ] && ok "~/.config/tmux/tmux.conf" || warn "tmux config missing"

    log "Git Config"
    git config --global user.name  &>/dev/null && ok "git user.name"  "($(git config --global user.name))"  || warn "git user.name not set"
    git config --global user.email &>/dev/null && ok "git user.email" "($(git config --global user.email))" || warn "git user.email not set"
    [ -f "$HOME/.ssh/github_ed25519.pub" ] && ok "SSH key" "($HOME/.ssh/github_ed25519.pub)" || warn "GitHub SSH key not found"

    log "Directory Structure"
    for dir in ai dev docs recovery projects workspace backups; do
        [ -d "$HOME/$dir" ] && ok "~/$dir" || warn "~/$dir directory missing"
    done
}

# ─── PATH check ───────────────────────────────────────────────────────────────
check_path() {
    log "PATH Validation"
    echo "  PATH: $PATH" | tr ':' '\n' | sed 's/^/  /'
    echo ""

    # Check Go is from correct location
    GO_BIN=$(command -v go 2>/dev/null)
    RUSTC_BIN=$(command -v rustc 2>/dev/null)
    NODE_BIN=$(command -v node 2>/dev/null)

    [[ "$GO_BIN" == "/usr/local/go/bin/go" ]] && ok "Go path" "($GO_BIN)" || warn "Go binary at unexpected path: $GO_BIN (expected /usr/local/go/bin/go)"
    [[ "$RUSTC_BIN" == *"/.cargo/bin/rustc" ]] && ok "Rust path" "($RUSTC_BIN)" || warn "Rust binary at unexpected path: $RUSTC_BIN"
    [[ "$NODE_BIN" == *"/.nvm/"* ]] && ok "Node path" "($NODE_BIN)" || warn "Node not from nvm: $NODE_BIN"
}

# ─── Summary ──────────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo "─────────────────────────────────────"
    if [ "$FAIL_COUNT" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}  All checks passed!${RESET}"
    else
        echo -e "${RED}${BOLD}  $FAIL_COUNT check(s) failed — see warnings above${RESET}"
    fi
    echo "─────────────────────────────────────"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║  Environment Check — OnePlus 7 Pro       ║"
echo "  ║  Ubuntu 24.04 ARM64 · ltangen            ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"

case "$MODE" in
    --tools)     check_tools; print_summary ;;
    --services)  check_services; print_summary ;;
    --ai)        check_ai; print_summary ;;
    --config)    check_config; check_path; print_summary ;;
    --full|*)
        check_tools
        check_services
        check_ai
        check_config
        check_path
        print_summary
        ;;
esac
