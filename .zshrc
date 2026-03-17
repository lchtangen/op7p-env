# ── ~/.zshrc ── ltangen · OnePlus 7 Pro · Ubuntu 24.04 ARM64 ──────────────────

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker docker-compose kubectl terraform python pip npm node golang)
source "$ZSH/oh-my-zsh.sh"

# ── System-wide interactive config ────────────────────────────────────────────
# (aliases, tools, services, plugins — see /etc/zsh/zshrc.local)
[[ -f /etc/zsh/zshrc.local ]] && source /etc/zsh/zshrc.local

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS INC_APPEND_HISTORY

# ── User env vars (workspace roots) ───────────────────────────────────────────
export WORKSPACE="$HOME/workspace"
export PROJECTS="$HOME/projects"
export AI_HOME="$HOME/ai"
export DEV="$HOME/dev"
export RECOVERY="$HOME/recovery"
export DOCS="$HOME/docs"
export BACKUPS="$HOME/backups"

# ── AI agents ─────────────────────────────────────────────────────────────────
alias review='bash $AI_HOME/agents/ai-review.sh'
alias explain='bash $AI_HOME/agents/ai-explain.sh'
alias ai-chat='bash $AI_HOME/agents/ai-chat.sh'
alias ai-commit='bash $AI_HOME/agents/ai-commit.sh'
alias ai-fix='bash $AI_HOME/agents/ai-fix.sh'
alias ai-code='bash $AI_HOME/agents/ai-chat.sh code'

# ── Dev scripts ───────────────────────────────────────────────────────────────
alias sysinfo='bash $DEV/scripts/linux/sysinfo.sh'
alias git-setup='bash $DEV/scripts/linux/git-setup.sh'
alias bootable='bash $RECOVERY/bootable/scripts/ventoy-install.sh'
alias perf-status='bash $DEV/scripts/linux/perf-tune.sh --status'
alias perf-tune='bash $DEV/scripts/linux/perf-tune.sh'
alias upgrade='bash $DEV/scripts/linux/upgrade-stack.sh'
alias env-check='bash $DEV/scripts/linux/env-check.sh'
alias mcp-setup='bash $DEV/scripts/linux/mcp-setup.sh'
alias vnc1080='bash $DEV/scripts/linux/vnc-desktop.sh start'
alias vncstop='bash $DEV/scripts/linux/vnc-desktop.sh stop'
alias vnc-status='bash $DEV/scripts/linux/vnc-desktop.sh status'

# ── Navigation alias overrides (fixes /etc/zsh/zshrc.local capitalisation) ───
# TODO: apply fix-zshrc-aliases.sh from Termux, then remove this block
alias ws='cd ~/workspace'
alias proj='cd ~/projects'
alias sandbox='cd ~/projects'
alias ai='cd ~/ai'
alias dev='cd ~/dev'
alias scripts='cd ~/dev/scripts'
alias docs='cd ~/docs'
alias recover='cd ~/recovery'
alias bak='cd ~/backups'
alias bak-zsh='cp ~/.zshrc ~/backups/dotfiles/.zshrc.bak'
alias bak-nvim='cp -r ~/.config/nvim ~/backups/dotfiles/nvim'
alias bak-tmux='cp ~/.config/tmux/tmux.conf ~/backups/dotfiles/tmux.conf'
alias jlab='jupyter lab --ip=0.0.0.0 --no-browser --notebook-dir="$HOME/ai/notebooks"'
alias jnb='jupyter notebook --ip=0.0.0.0 --no-browser --notebook-dir="$HOME/ai/notebooks"'

# ── Login banner ──────────────────────────────────────────────────────────────
echo ""
echo "  Ubuntu 24.04 ARM64 · OnePlus 7 Pro GM1913 · ltangen"
echo "  ─────────────────────────────────────────────────────"
echo "  vnc1080 / vncstop     VNC desktop (port 5901)"
echo "  ta                    tmux attach/new"
echo "  ai-chat / ai-code     Ollama interactive chat"
echo "  ai-commit / ai-fix    AI git + code tools"
echo "  cc / ccc              Claude Code"
echo "  env-check             validate environment"
echo "  proj / ai / dev       quick navigate"
echo ""
