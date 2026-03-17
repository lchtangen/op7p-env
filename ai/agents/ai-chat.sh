#!/bin/bash
# ai-chat.sh — Ollama chat launcher with model selection
# Usage: ai-chat [code|chat|fast] [--model <name>] [--system "prompt"]

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

MODEL="${1:-qwen2.5-coder:7b}"
SYSTEM_PROMPT=""

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --system) SYSTEM_PROMPT="$2"; shift 2 ;;
        --model|-m) MODEL="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: ai [model] [options]"
            echo "  Models: code (qwen2.5-coder:7b), chat (llama3.2:3b), fast (smollm2:135m)"
            echo "  Options: --system \"prompt\", --model <name>"
            exit 0 ;;
        code) MODEL="qwen2.5-coder:7b"; shift ;;
        chat) MODEL="llama3.2:3b"; shift ;;
        fast) MODEL="smollm2:135m"; shift ;;
        *) shift ;;
    esac
done

# Check ollama is running
if ! curl -s http://127.0.0.1:11434 > /dev/null 2>&1; then
    echo -e "${YELLOW}Starting Ollama...${RESET}"
    ollama serve > /var/log/ollama.log 2>&1 &
    sleep 2
fi

echo -e "${CYAN}${BOLD} Ollama AI — ${MODEL}${RESET}"
echo -e "${CYAN}Type your message. Ctrl+D or 'exit' to quit.${RESET}\n"

if [ -n "$SYSTEM_PROMPT" ]; then
    ollama run "$MODEL" --system "$SYSTEM_PROMPT"
else
    ollama run "$MODEL"
fi
