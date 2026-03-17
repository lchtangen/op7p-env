#!/bin/bash
# ai-review.sh — AI code review using local Ollama
# Usage: review <file>  OR  cat file | review

MODEL="qwen2.5-coder:7b"
SYSTEM="You are an expert code reviewer. Analyze the code for: bugs, security issues, performance, style, and best practices. Be concise and specific. Format output as: ISSUES (if any), SUGGESTIONS, QUALITY SCORE (1-10)."

if [ -n "$1" ] && [ -f "$1" ]; then
    CODE=$(cat "$1")
    LANG=$(echo "$1" | sed 's/.*\.//')
    echo -e "\033[0;36m\033[1mReviewing: $1\033[0m\n"
    echo "Review this $LANG code:

$CODE" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
elif [ ! -t 0 ]; then
    CODE=$(cat)
    echo -e "\033[0;36m\033[1mReviewing stdin input...\033[0m\n"
    echo "Review this code:

$CODE" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
else
    echo "Usage: review <file>  OR  cat file.py | review"
    exit 1
fi
