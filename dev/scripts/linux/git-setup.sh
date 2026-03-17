#!/bin/bash
# github-setup.sh — Complete GitHub CLI + Git setup for OnePlus 7 Pro Ubuntu
# Run once to authenticate and configure GitHub
# Usage: bash github-setup.sh

set -e
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║  GitHub Setup — OnePlus 7 Pro Ubuntu ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${RESET}"

# 1. Install GitHub CLI if missing
if ! command -v gh &>/dev/null; then
    echo -e "${YELLOW}Installing GitHub CLI (gh)...${RESET}"
    sudo apt install -y gh
    echo -e "${GREEN}gh installed: $(gh --version | head -1)${RESET}"
fi

# 2. Git global config
echo -e "\n${CYAN}${BOLD}Git Configuration${RESET}"
read -rp "Your name [Tangen]: " NAME
NAME="${NAME:-Tangen}"
read -rp "Your email: " EMAIL
read -rp "GitHub username [lchtangen]: " GHUSER
GHUSER="${GHUSER:-lchtangen}"

git config --global user.name "$NAME"
git config --global user.email "$EMAIL"
git config --global core.editor "nvim"
git config --global init.defaultBranch "main"
git config --global pull.rebase false
git config --global credential.helper store
git config --global core.autocrlf input
git config --global push.autoSetupRemote true

echo -e "${GREEN}Git config set.${RESET}"

# 3. SSH key for GitHub
echo -e "\n${CYAN}${BOLD}SSH Key Setup${RESET}"
SSH_KEY="$HOME/.ssh/github_ed25519"

if [ ! -f "$SSH_KEY" ]; then
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""

    # SSH config
    cat >> ~/.ssh/config << EOF

Host github.com
  HostName github.com
  User git
  IdentityFile $SSH_KEY
  AddKeysToAgent yes
EOF
    chmod 600 ~/.ssh/config

    echo -e "${GREEN}SSH key created: $SSH_KEY${RESET}"
    echo -e "${YELLOW}Public key (add to GitHub → Settings → SSH Keys):${RESET}"
    cat "${SSH_KEY}.pub"
    echo ""
    echo -e "${CYAN}Open: https://github.com/settings/keys${RESET}"
    read -rp "Press ENTER after adding the key to GitHub..."
else
    echo -e "${GREEN}SSH key already exists: $SSH_KEY${RESET}"
fi

# 4. GitHub CLI auth
echo -e "\n${CYAN}${BOLD}GitHub CLI Authentication${RESET}"
if ! gh auth status &>/dev/null; then
    echo -e "${YELLOW}Opening GitHub auth...${RESET}"
    echo "Choose: GitHub.com → SSH → Authenticate with SSH key"
    echo "(If browser doesn't open, copy the code and go to github.com/login/device)"
    gh auth login
else
    echo -e "${GREEN}Already authenticated:${RESET}"
    gh auth status
fi

# 5. Test
echo -e "\n${CYAN}${BOLD}Testing Connection${RESET}"
ssh -T git@github.com 2>&1 | grep -i "Hi\|authenticated\|denied\|Error" || true
gh api user --jq '.login' 2>/dev/null && echo -e "${GREEN}GitHub API: connected as $(gh api user --jq '.login')${RESET}" || echo -e "${YELLOW}Run 'gh auth login' manually if needed${RESET}"

echo -e "\n${GREEN}${BOLD}GitHub setup complete!${RESET}"
echo -e "Clone repos: ${CYAN}gh repo clone $GHUSER/<repo-name> ~/projects/<repo-name>${RESET}"
