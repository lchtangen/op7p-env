#!/bin/bash
# ollama-config.sh — Optimize Ollama for OnePlus 7 Pro (SM8150, 12GB RAM)
# Configures CPU affinity, thread count, context size, model preloading
# Usage: bash ollama-config.sh [--apply|--status|--bench]

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RESET=$'\033[0m'

MODE="${1:---status}"
log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
info() { echo -e "  $1"; }

# SM8150 CPU layout for Ollama affinity
# cpus 4-7 = MID + PRIME cores (high-performance)
# cpus 0-3 = LITTLE cores (efficiency, leave for Android/OS)
PERF_CPUS="4-7"       # 3× MID (2.4GHz) + 1× PRIME (2.84GHz)
NUM_THREADS=4         # match perf core count
CTX_SIZE=4096         # context window (4k = good for 12GB RAM)
MAX_LOADED=1          # max models in memory simultaneously

show_status() {
    log "Ollama Status"
    info "Version:     $(ollama --version 2>/dev/null)"
    info "Host:        ${OLLAMA_HOST:-127.0.0.1:11434}"
    info "Models:"
    ollama list 2>/dev/null | tail -n +2 | while read -r line; do
        info "  $line"
    done
    info ""
    info "Current env vars:"
    env | grep OLLAMA || info "  (none set)"
    info ""
    info "Running processes:"
    pgrep -a ollama 2>/dev/null | head -3 || info "  (not running)"
}

apply_config() {
    log "Applying Ollama optimizations"

    # Update systemd service with performance options
    if [ -f /etc/systemd/system/ollama.service ]; then
        info "Patching ollama.service..."
        cat > /etc/systemd/system/ollama.service << 'EOF'
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3

# SM8150 optimization: run on high-performance cores (MID + PRIME)
CPUAffinity=4 5 6 7

# Memory & threading
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_KEEP_ALIVE=10m"
Environment="OLLAMA_HOST=127.0.0.1:11434"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Limits
LimitNOFILE=65536
LimitMEMLOCK=infinity
Nice=-10

[Install]
WantedBy=default.target
EOF
        systemctl daemon-reload 2>/dev/null && ok "ollama.service updated"
    else
        warn "/etc/systemd/system/ollama.service not found — manual Ollama"
    fi

    # Write user-level environment for interactive sessions
    OLLAMA_ENV="$HOME/.config/ollama/env"
    mkdir -p "$(dirname "$OLLAMA_ENV")"
    cat > "$OLLAMA_ENV" << EOF
# Ollama user env — OnePlus 7 Pro optimized
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=10m
EOF
    ok "Ollama env written: $OLLAMA_ENV"
    ok "Source with: source ~/.config/ollama/env"

    info ""
    info "CPU affinity: cores $PERF_CPUS (MID + PRIME) → max Ollama performance"
    info "RAM budget:   ~7GB available for models (12GB total, 5GB OS/services)"
    info "Recommended model sizes for this device:"
    info "  smollm2:135m  — instant   (270MB)"
    info "  llama3.2:3b   — fast      (2.0GB)"
    info "  qwen2.5-coder:7b — quality (4.7GB) ← best fit for 12GB"
    info "  llama3.1:8b   — large     (4.7GB) ← also fits"
    info "  gemma3:12b    — max       (8.1GB) ← tight, may swap"
}

bench_model() {
    log "Benchmarking Ollama inference (smollm2:135m)"
    info "Prompt: 'Write a Python hello world function'"
    START=$(date +%s%N)
    echo "Write a Python hello world function" | ollama run smollm2:135m --nowordwrap 2>/dev/null
    END=$(date +%s%N)
    ELAPSED=$(( (END - START) / 1000000 ))
    ok "Completed in ${ELAPSED}ms"
}

case "$MODE" in
    --status) show_status ;;
    --apply)  apply_config ;;
    --bench)  bench_model ;;
    *)
        show_status
        echo ""
        info "Usage: $0 [--status|--apply|--bench]"
        ;;
esac
