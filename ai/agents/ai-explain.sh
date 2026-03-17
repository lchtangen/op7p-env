#!/bin/bash
# ai-explain.sh — explain code or terminal output using local AI
# Usage: explain <file>  OR  <cmd> | explain  OR  explain "concept"

MODEL="qwen2.5-coder:7b"
SYSTEM="You are a helpful developer assistant. Explain clearly and concisely. Use bullet points for lists. Focus on what, why, and how."

if [ -n "$1" ] && [ -f "$1" ]; then
    echo "Explain this code in detail:
$(cat "$1")" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
elif [ ! -t 0 ]; then
    INPUT=$(cat)
    echo "Explain this:
$INPUT" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
elif [ -n "$1" ]; then
    echo "$*" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
else
    echo "Usage: explain <file|concept>  OR  <cmd> | explain"
fi
