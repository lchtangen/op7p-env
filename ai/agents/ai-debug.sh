#!/bin/bash
# ai-debug.sh — Analyze error output, logs, and crash messages using local AI
# Usage: ai-debug <file>  OR  <cmd> 2>&1 | ai-debug  OR  ai-debug "error message"

MODEL="qwen2.5-coder:7b"
SYSTEM="You are an expert debugger and systems engineer. Analyze the provided error output, log, or crash message. Provide: 1) ROOT CAUSE — what went wrong and why. 2) FIX — specific steps to resolve it. 3) PREVENTION — how to avoid this in future. Be precise and actionable. Focus on ARM64/Linux/Android environments when relevant."

CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

if [ -n "${1:-}" ] && [ -f "$1" ]; then
    echo -e "${CYAN}${BOLD}Analyzing file: $1${RESET}\n"
    echo "Debug this error/log output:
$(cat "$1")" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
elif [ ! -t 0 ]; then
    INPUT=$(cat)
    echo -e "${CYAN}${BOLD}Analyzing input...${RESET}\n"
    echo "Debug this error/log output:
$INPUT" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
elif [ -n "${1:-}" ]; then
    echo -e "${CYAN}${BOLD}Analyzing: $*${RESET}\n"
    echo "Debug this error:
$*" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
else
    echo "Usage: ai-debug <file|'error message'>  OR  <cmd> 2>&1 | ai-debug"
    echo ""
    echo "Examples:"
    echo "  dmesg | tail -20 | ai-debug"
    echo "  journalctl -u ollama | ai-debug"
    echo "  cargo build 2>&1 | ai-debug"
    echo "  ai-debug /var/log/syslog"
    exit 1
fi
