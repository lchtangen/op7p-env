#!/bin/bash
# ai-fix.sh — AI code fixer: analyzes a file, outputs a unified diff of suggested fixes
# Usage: ai-fix <file> [--apply]
#   ai-fix src/main.go          # show diff of suggested fixes
#   ai-fix src/main.go --apply  # apply fixes directly to the file

MODEL="qwen2.5-coder:7b"
SYSTEM="You are an expert code fixer. When given code, output ONLY a unified diff (patch format) of fixes for bugs, errors, and obvious issues. Do NOT add explanations, comments, or prose — output ONLY the unified diff starting with --- and +++. If no fixes are needed, output: NO_FIXES_NEEDED"

BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'; RESET='\033[0m'

FILE="${1:-}"
APPLY="${2:-}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "Usage: ai-fix <file> [--apply]"
    echo "  ai-fix src/main.go          # show suggested fixes as diff"
    echo "  ai-fix src/main.go --apply  # apply fixes to the file"
    exit 1
fi

# Check ollama is reachable
if ! curl -s http://127.0.0.1:11434 > /dev/null 2>&1; then
    echo -e "${YELLOW}Starting Ollama...${RESET}"
    ollama serve > /var/log/ollama.log 2>&1 &
    sleep 2
fi

LANG=$(echo "$FILE" | sed 's/.*\.//')
CODE=$(cat "$FILE")

echo -e "${CYAN}${BOLD}Analyzing: $FILE${RESET}"
echo ""

PATCH=$(printf "Fix all bugs in this %s file. Output unified diff only:\n\n%s" "$LANG" "$CODE" \
    | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap 2>/dev/null)

if [ -z "$PATCH" ] || [ "$PATCH" = "NO_FIXES_NEEDED" ]; then
    echo -e "${GREEN}No fixes needed.${RESET}"
    exit 0
fi

echo -e "${BOLD}Suggested fixes (unified diff):${RESET}"
echo "─────────────────────────────────────"
echo "$PATCH"
echo "─────────────────────────────────────"

if [ "$APPLY" = "--apply" ]; then
    TMPFILE=$(mktemp /tmp/ai-fix-XXXXXX.patch)
    echo "$PATCH" > "$TMPFILE"

    if patch --dry-run "$FILE" "$TMPFILE" > /dev/null 2>&1; then
        patch "$FILE" "$TMPFILE"
        echo -e "${GREEN}Fixes applied to $FILE${RESET}"
        rm -f "$TMPFILE"
    else
        echo -e "${YELLOW}Patch could not be applied cleanly. Saved to: $TMPFILE${RESET}"
        echo "Review and apply manually: patch $FILE $TMPFILE"
    fi
fi
