#!/bin/bash
# ai-docs.sh — Generate documentation for code files using local AI
# Usage: ai-docs <file> [--format md|rst|docstring]

MODEL="qwen2.5-coder:7b"

CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

FILE=""
FORMAT_TYPE="md"

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --format|-f) FORMAT_TYPE="$2"; shift 2 ;;
        *) FILE="${FILE:-$1}"; shift ;;
    esac
done

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "Usage: ai-docs <file> [--format md|rst|docstring]"
    echo ""
    echo "Examples:"
    echo "  ai-docs src/main.py"
    echo "  ai-docs api/handler.go --format md"
    echo "  ai-docs lib/utils.rs --format docstring"
    exit 1
fi

EXT="${FILE##*.}"
LANG="$EXT"

# Determine format-specific system prompt
case "$FORMAT_TYPE" in
    docstring)
        SYSTEM="You are a documentation expert. Add proper docstrings/comments to the provided code. For Python use Google-style docstrings. For Go/Rust/JavaScript use the native doc comment format. Return ONLY the fully-documented code, preserving all original logic."
        PROMPT="Add complete docstrings and inline comments to this $LANG code:"
        ;;
    rst)
        SYSTEM="You are a technical documentation writer. Generate reStructuredText (RST) documentation for the provided code. Include: module/file overview, all functions/classes with parameters and return types, usage examples."
        PROMPT="Generate RST documentation for this $LANG code:"
        ;;
    *)
        SYSTEM="You are a technical documentation writer. Generate clear Markdown documentation for the provided code. Include: ## Overview, ## Functions/API (with parameters, return values, examples), ## Usage Examples. Be accurate and developer-focused."
        PROMPT="Generate Markdown documentation for this $LANG code:"
        ;;
esac

echo -e "${CYAN}${BOLD}Generating docs for: $FILE (format: ${FORMAT_TYPE})${RESET}\n"

echo "$PROMPT

$(cat "$FILE")" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
