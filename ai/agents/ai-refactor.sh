#!/bin/bash
# ai-refactor.sh — AI-powered code refactoring suggestions
# Usage: ai-refactor <file> [--goal "description"]

MODEL="qwen2.5-coder:7b"
SYSTEM="You are a senior software engineer specializing in code quality and refactoring. Analyze the provided code and suggest concrete refactoring improvements. Focus on: readability, DRY principle, error handling, performance, idiomatic patterns for the language. Provide the refactored code with brief comments explaining each improvement. Output format: 1) ISSUES FOUND, 2) REFACTORED CODE, 3) EXPLANATION OF CHANGES."

CYAN='\033[0;36m'; BOLD='\033[1m'; YELLOW='\033[0;33m'; RESET='\033[0m'

FILE="${1:-}"
GOAL=""

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --goal|-g) GOAL="$2"; shift 2 ;;
        *) FILE="${FILE:-$1}"; shift ;;
    esac
done

if [ -z "$FILE" ]; then
    if [ ! -t 0 ]; then
        CODE=$(cat)
        echo -e "${CYAN}${BOLD}Refactoring stdin input...${RESET}\n"
        PROMPT="Refactor this code${GOAL:+ with goal: $GOAL}:

$CODE"
        echo "$PROMPT" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
        exit 0
    fi
    echo "Usage: ai-refactor <file> [--goal 'make it async']"
    echo ""
    echo "Examples:"
    echo "  ai-refactor src/handler.py"
    echo "  ai-refactor api/routes.go --goal 'add proper error handling'"
    echo "  cat messy_code.sh | ai-refactor"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

EXT="${FILE##*.}"
echo -e "${CYAN}${BOLD}Refactoring: $FILE${RESET}"
[ -n "$GOAL" ] && echo -e "${YELLOW}Goal: $GOAL${RESET}"
echo ""

PROMPT="Refactor this ${EXT} code${GOAL:+ to $GOAL}:

$(cat "$FILE")"

echo "$PROMPT" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
