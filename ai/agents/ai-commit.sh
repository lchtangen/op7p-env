#!/bin/bash
# ai-commit.sh — AI-generated git commit messages using local Ollama
# Analyzes staged diff and writes a conventional commit message
# Usage: ai-commit [--apply] [--amend]

MODEL="qwen2.5-coder:7b"
SYSTEM="You are a git commit message expert. Generate a concise, conventional commit message from the provided diff. Format: <type>(<scope>): <short summary> (50 chars max). Types: feat, fix, docs, style, refactor, test, chore, perf. Add a blank line then a brief body if the change is complex. Output ONLY the commit message, no extra text."

BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RESET='\033[0m'

APPLY=false
AMEND=false

for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=true ;;
        --amend) AMEND=true; APPLY=true ;;
    esac
done

# Check git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not a git repository."
    exit 1
fi

# Get the diff to analyze
if git diff --cached --quiet 2>/dev/null && [ "$AMEND" = false ]; then
    echo -e "${YELLOW}No staged changes found. Stage files first: git add <files>${RESET}"
    echo "Or use --amend to regenerate the last commit message."
    exit 1
fi

if [ "$AMEND" = true ]; then
    DIFF=$(git diff HEAD~1 HEAD 2>/dev/null || git diff --cached)
else
    DIFF=$(git diff --cached)
fi

if [ -z "$DIFF" ]; then
    echo -e "${YELLOW}Empty diff — nothing to generate a message for.${RESET}"
    exit 1
fi

echo -e "${CYAN}${BOLD} Generating commit message...${RESET}\n"

MSG=$(echo "Generate a git commit message for this diff:

$DIFF" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap 2>/dev/null)

echo -e "${GREEN}${BOLD}Suggested commit message:${RESET}\n"
echo "─────────────────────────────────────"
echo "$MSG"
echo "─────────────────────────────────────"
echo ""

if [ "$APPLY" = true ]; then
    if [ "$AMEND" = true ]; then
        git commit --amend -m "$MSG"
        echo -e "${GREEN}✓ Last commit amended with new message.${RESET}"
    else
        git commit -m "$MSG"
        echo -e "${GREEN}✓ Committed with generated message.${RESET}"
    fi
else
    echo -e "${YELLOW}Tip: Run 'git commit -m \"$MSG\"' to use this message."
    echo -e "     Or run 'ai-commit --apply' to commit automatically.${RESET}"
fi
