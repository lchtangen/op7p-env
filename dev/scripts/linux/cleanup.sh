#!/bin/bash
# cleanup.sh — safe system cleanup for OnePlus 7 Pro Ubuntu
# Usage: cleanup [--deep]

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${BOLD}Starting cleanup...${RESET}"

echo -e "\n${YELLOW}1. APT cache cleanup${RESET}"
sudo apt autoremove -y 2>/dev/null
sudo apt autoclean 2>/dev/null
sudo apt clean 2>/dev/null

echo -e "\n${YELLOW}2. Pip cache${RESET}"
pip3 cache purge 2>/dev/null

echo -e "\n${YELLOW}3. npm cache${RESET}"
npm cache clean --force 2>/dev/null

echo -e "\n${YELLOW}4. Old log files (>7 days)${RESET}"
sudo find /var/log -name "*.gz" -mtime +7 -delete 2>/dev/null
sudo find /var/log -name "*.1" -mtime +7 -delete 2>/dev/null
sudo journalctl --vacuum-time=7d 2>/dev/null || true

echo -e "\n${YELLOW}5. Temp files${RESET}"
find /tmp -maxdepth 1 -mtime +1 -not -name "." -delete 2>/dev/null || true

echo -e "\n${YELLOW}6. Zsh compdump cache${RESET}"
find "$HOME" -maxdepth 1 -name ".zcompdump*" -not -newer "$HOME/.zshrc" -delete 2>/dev/null || true

if [ "$1" = "--deep" ]; then
    echo -e "\n${YELLOW}7. Docker cleanup (deep)${RESET}"
    docker system prune -f 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true

    echo -e "\n${YELLOW}8. Ollama model cache${RESET}"
    echo "  Current models:"
    ollama list 2>/dev/null | tail -n +2
    echo "  Use 'ollama rm <model>' to remove unused models"
fi

echo -e "\n${GREEN}${BOLD}Cleanup complete!${RESET}"
