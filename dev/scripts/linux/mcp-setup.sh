#!/bin/bash
# mcp-setup.sh — Model Context Protocol (MCP) server setup for Claude Code
# Configures local MCP servers to extend Claude's capabilities on the device
# Usage: bash mcp-setup.sh [--install|--status|--list|--reset]
#
# MCP servers installed:
#   filesystem    — Read/write access to home directory
#   git           — Git operations and repository management
#   sqlite        — Local SQLite database access
#   fetch         — HTTP fetch for documentation and APIs
#   shell         — Safe shell command execution
#
# Docs: https://docs.anthropic.com/en/docs/build-with-claude/mcp

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
info() { echo -e "  $1"; }

MODE="${1:---status}"

# MCP config location for Claude Code
CLAUDE_CONFIG_DIR="$HOME/.claude"
MCP_CONFIG="$CLAUDE_CONFIG_DIR/claude_mcp_config.json"
CLAUDE_SETTINGS="$CLAUDE_CONFIG_DIR/settings.json"

show_status() {
    log "MCP Status"

    command -v claude &>/dev/null && ok "Claude Code CLI" "($(claude --version 2>/dev/null | head -1))" || warn "Claude Code not found (install: npm install -g @anthropic-ai/claude-code)"
    command -v node   &>/dev/null && ok "Node.js runtime" "($(node --version 2>/dev/null))" || warn "Node.js not found"
    command -v npx    &>/dev/null && ok "npx" || warn "npx not found"

    echo ""
    if [ -f "$MCP_CONFIG" ]; then
        ok "MCP config found: $MCP_CONFIG"
        if command -v python3 &>/dev/null; then
            info "Configured MCP servers:"
            python3 - "$MCP_CONFIG" <<'PYEOF'
import sys, json
try:
    data = json.load(open(sys.argv[1]))
    for name, cfg in data.get("mcpServers", {}).items():
        print(f"  · {name}: {cfg.get('command', '?')} {' '.join(cfg.get('args', []))[:60]}")
except Exception as e:
    print(f"  Error reading config: {e}")
PYEOF
        fi
    else
        warn "MCP config not found: $MCP_CONFIG"
        warn "Run: bash $0 --install"
    fi
}

install_mcp() {
    log "Installing MCP servers"

    # Verify Node.js is available
    command -v node &>/dev/null || { warn "Node.js required — run: nvm install --lts"; exit 1; }
    command -v npx  &>/dev/null || { warn "npx not found — check Node installation"; exit 1; }

    mkdir -p "$CLAUDE_CONFIG_DIR"

    # Install MCP server packages globally
    log "Installing MCP packages (npm)"
    npm install -g \
        @modelcontextprotocol/server-filesystem \
        @modelcontextprotocol/server-git \
        @modelcontextprotocol/server-sqlite \
        @modelcontextprotocol/server-fetch \
        2>&1 | tail -5
    ok "MCP npm packages installed"

    # Write MCP configuration
    log "Writing MCP config: $MCP_CONFIG"
    cat > "$MCP_CONFIG" << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "${HOME}"
      ],
      "description": "Read/write access to home directory (${HOME})"
    },
    "git": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-git",
        "--repository",
        "${HOME}/projects"
      ],
      "description": "Git repository operations in ~/projects"
    },
    "sqlite": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sqlite",
        "--db-path",
        "${HOME}/workspace/local.db"
      ],
      "description": "Local SQLite database at ~/workspace/local.db"
    },
    "fetch": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-fetch"
      ],
      "description": "HTTP fetch for documentation and web APIs"
    }
  }
}
EOF
    ok "MCP config written: $MCP_CONFIG"

    echo ""
    info "MCP servers configured. Claude Code will use these automatically."
    info "Test with: claude --mcp-status"
    echo ""
    info "Server capabilities:"
    info "  filesystem  → Claude can read/write files in $HOME"
    info "  git         → Claude can create commits, branches, PRs in ~/projects"
    info "  sqlite      → Claude can query/modify ~/workspace/local.db"
    info "  fetch       → Claude can retrieve web documentation"
}

list_available() {
    log "Available MCP Servers (ARM64 compatible)"
    echo ""
    cat << 'EOF'
  Official (Anthropic):
    @modelcontextprotocol/server-filesystem    File system R/W access
    @modelcontextprotocol/server-git           Git operations
    @modelcontextprotocol/server-sqlite        SQLite database
    @modelcontextprotocol/server-fetch         HTTP requests
    @modelcontextprotocol/server-memory        In-session persistent memory
    @modelcontextprotocol/server-puppeteer     Browser automation (needs Chrome)
    @modelcontextprotocol/server-brave-search  Web search via Brave API

  Community (check ARM64 compatibility):
    mcp-server-redis          Redis key-value store
    mcp-server-postgres       PostgreSQL database
    mcp-server-docker         Docker container management
    mcp-server-kubernetes     Kubernetes cluster management

  Install any server:
    npm install -g <package-name>
    Then add to ~/.claude/claude_mcp_config.json

  Full list: https://github.com/modelcontextprotocol/servers
EOF
}

reset_mcp() {
    log "Resetting MCP config"
    if [ -f "$MCP_CONFIG" ]; then
        cp "$MCP_CONFIG" "${MCP_CONFIG}.bak-$(date +%Y%m%d%H%M%S)"
        rm -f "$MCP_CONFIG"
        ok "MCP config removed (backup kept)"
    else
        info "No MCP config to remove"
    fi
}

case "$MODE" in
    --install) install_mcp ;;
    --status)  show_status ;;
    --list)    list_available ;;
    --reset)   reset_mcp ;;
    *)
        info "Usage: $0 [--install|--status|--list|--reset]"
        show_status
        ;;
esac
