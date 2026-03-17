#!/bin/bash
# ai-stack.sh — Manage the complete AI stack on OnePlus 7 Pro
# Ollama service, model management, Python AI packages, LangChain
# Usage: bash ai-stack.sh [--status|--start|--stop|--restart|--models|--install|--bench]

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

MODE="${1:---status}"
log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
err()  { echo -e "${RED}  ✗ $1${RESET}"; }
info() { echo -e "  $1"; }

OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
LOG_DIR="${HOME}/.local/log"
OLLAMA_LOG="${LOG_DIR}/ollama.log"

show_status() {
    log "AI Stack Status — OnePlus 7 Pro SM8150"

    # Ollama
    if curl -s "http://${OLLAMA_HOST}" > /dev/null 2>&1; then
        ok "Ollama: running at http://${OLLAMA_HOST}"
        info "  Models loaded: $(ollama ps 2>/dev/null | tail -n +2 | wc -l)"
    else
        warn "Ollama: stopped"
    fi

    # Python AI packages
    info ""
    info "Python AI packages:"
    for pkg in anthropic openai langchain langchain-ollama fastapi uvicorn litellm huggingface_hub; do
        VERSION=$(python3 -c "import importlib.metadata; print(importlib.metadata.version('$pkg'))" 2>/dev/null || echo "not installed")
        printf "  %-22s %s\n" "$pkg" "$VERSION"
    done

    # Models
    log "Installed Ollama Models"
    ollama list 2>/dev/null | tail -n +2 | while read -r line; do
        info "  $line"
    done

    # RAM
    log "Memory"
    free -h | grep -E "Mem|Swap" | while read -r line; do
        info "  $line"
    done
}

start_ollama() {
    if curl -s "http://${OLLAMA_HOST}" > /dev/null 2>&1; then
        ok "Ollama already running at http://${OLLAMA_HOST}"
        return
    fi
    log "Starting Ollama"
    mkdir -p "$LOG_DIR"
    taskset -c 4-7 ollama serve > "$OLLAMA_LOG" 2>&1 &
    local pid=$!
    echo "  PID: $pid"
    sleep 3
    if curl -s "http://${OLLAMA_HOST}" > /dev/null 2>&1; then
        ok "Ollama started (log: $OLLAMA_LOG)"
    else
        err "Ollama failed to start — check $OLLAMA_LOG"
    fi
}

stop_ollama() {
    log "Stopping Ollama"
    if pkill -f "ollama serve" 2>/dev/null; then
        ok "Ollama stopped"
    else
        warn "Ollama was not running"
    fi
}

install_packages() {
    log "Installing/upgrading AI Python packages"
    pip3 install --upgrade \
        anthropic openai \
        langchain langchain-community langchain-ollama langchain-core \
        fastapi uvicorn httpx \
        litellm \
        huggingface_hub \
        ollama \
        2>&1 | tail -5
    ok "AI packages installed"

    log "Installing optional orchestration packages"
    pip3 install --upgrade \
        crewai \
        2>&1 | tail -3 || warn "crewai install failed (optional)"

    info ""
    info "Installed packages:"
    info "  langchain + langchain-ollama  — LLM chains, agents, tools"
    info "  litellm                       — unified API for 100+ LLM providers"
    info "  anthropic + openai            — cloud provider SDKs"
    info "  crewai                        — multi-agent orchestration"
    info "  ollama                        — Python Ollama client"
    info "  fastapi + uvicorn             — REST API server"
}

bench_models() {
    log "Benchmarking installed models"
    PROMPT="What is the capital of France? Answer in one word."
    ollama list 2>/dev/null | tail -n +2 | while read -r line; do
        MODEL=$(echo "$line" | awk '{print $1}')
        [ -z "$MODEL" ] && continue
        START=$(date +%s%N)
        RESULT=$(echo "$PROMPT" | ollama run "$MODEL" --nowordwrap 2>/dev/null | head -1)
        END=$(date +%s%N)
        ELAPSED=$(( (END - START) / 1000000 ))
        printf "  %-30s %s ms  |  %s\n" "$MODEL" "$ELAPSED" "$RESULT"
    done
}

pull_essential_models() {
    log "Pulling essential models"
    info "Pulling smollm2:135m (270MB — fast completions)..."
    ollama pull smollm2:135m
    info ""
    info "Pulling llama3.2:3b (2GB — general chat)..."
    ollama pull llama3.2:3b
    info ""
    info "Pulling qwen2.5-coder:7b (4.7GB — code — primary)..."
    ollama pull qwen2.5-coder:7b
    ok "Essential models installed"
}

show_models() {
    log "Available Models"
    info "  ── Installed ─────────────────────────────────"
    ollama list 2>/dev/null | tail -n +2 | while read -r line; do
        info "  ✓ $line"
    done
    info ""
    info "  ── Recommended for SM8150 (12GB) ─────────────"
    info "  smollm2:135m      270 MB   Instant, always-on"
    info "  llama3.2:3b       2.0 GB   General chat"
    info "  qwen2.5-coder:7b  4.7 GB   Code — primary ✓"
    info "  qwen2.5:7b        4.7 GB   Multilingual, reasoning"
    info "  llama3.1:8b       4.7 GB   Best general 8b"
    info "  gemma3:4b         2.5 GB   Google Gemma 3, efficient"
    info "  gemma3:12b        8.1 GB   Google Gemma 3, best quality"
    info "  phi4:14b          8.5 GB   Microsoft Phi-4"
    info "  mistral:7b        4.1 GB   Fast instruction following"
    info ""
    info "  Pull: ollama pull <model>"
    info "        bash ai-stack.sh --pull-essential"
}

case "$MODE" in
    --status)         show_status ;;
    --start)          start_ollama ;;
    --stop)           stop_ollama ;;
    --restart)        stop_ollama; sleep 1; start_ollama ;;
    --install)        install_packages ;;
    --models)         show_models ;;
    --bench)          bench_models ;;
    --pull-essential) pull_essential_models ;;
    *)
        show_status
        echo ""
        info "Usage: ai-stack.sh [--status|--start|--stop|--restart|--install|--models|--bench|--pull-essential]"
        ;;
esac
