#!/bin/bash
# ai-commit.sh — AI-powered git commit message generator
# Usage: ai-commit [--staged|--all|--amend]
#   --staged   Generate message for staged changes (default)
#   --all      Stage all changes and generate message
#   --amend    Generate improved message for most recent commit
#   --push     Generate, commit, and push in one step

MODEL="qwen2.5-coder:7b"
SYSTEM="You are an expert at writing clear, concise git commit messages following the Conventional Commits specification. Given a git diff, write a commit message that:
1. First line: type(scope): brief description (max 72 chars)
   Types: feat, fix, docs, style, refactor, perf, test, chore, build, ci
2. Optional body: explain WHY the change was made (not what — that's in the diff)
3. Optional footer: BREAKING CHANGE: or Refs: #issue

Rules:
- Use imperative mood: 'add feature' not 'added feature'
- Be specific about what changed, not generic ('update code' is bad)
- If multiple changes, use bullet points in body
- Output ONLY the commit message text — no preamble or explanation"

BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[0;33m'; RED='\033[0;31m'; RESET='\033[0m'

MODE="${1:---staged}"

# Ensure we are in a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Not in a git repository.${RESET}"
    exit 1
fi

# Check ollama is reachable
if ! curl -s http://127.0.0.1:11434 > /dev/null 2>&1; then
    echo -e "${YELLOW}Starting Ollama...${RESET}"
    ollama serve > /var/log/ollama.log 2>&1 &
    sleep 2
fi

case "$MODE" in
    --all)
        git add -A
        DIFF=$(git diff --cached)
        ;;
    --amend)
        DIFF=$(git show --stat HEAD)$'\n\n'"$(git show HEAD)"
        ;;
    --staged|*)
        DIFF=$(git diff --cached)
        ;;
esac

if [ -z "$DIFF" ]; then
    echo -e "${YELLOW}No staged changes found.${RESET}"
    echo "Stage changes first:  git add <files>  or use --all"
    exit 1
fi

# Truncate diff if very large (Ollama context limit)
MAX_DIFF_CHARS=8000
if [ ${#DIFF} -gt $MAX_DIFF_CHARS ]; then
    DIFF="${DIFF:0:$MAX_DIFF_CHARS}"$'\n\n'"[... diff truncated for context ...]"
fi

echo -e "${CYAN}${BOLD}Generating commit message...${RESET}"
echo ""

MSG=$(printf "Generate a commit message for this git diff:\n\n%s" "$DIFF" \
    | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap 2>/dev/null)

echo -e "${GREEN}${BOLD}Suggested commit message:${RESET}"
echo "─────────────────────────────────────"
echo "$MSG"
echo "─────────────────────────────────────"
echo ""

if [ "$MODE" = "--push" ]; then
    read -rp "Use this message and push? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        git commit -m "$MSG"
        git push
        echo -e "${GREEN}Committed and pushed.${RESET}"
    else
        echo "Aborted."
    fi
else
    echo "To use:  git commit -m \"\$(ai-commit | tail -n +6 | head -n -3)\""
    echo "Or copy the message above."
    read -rp "Commit with this message? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        git commit -m "$MSG"
        echo -e "${GREEN}Committed.${RESET}"
    fi
fi
