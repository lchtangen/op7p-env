#!/bin/bash
# sysinfo.sh — OnePlus 7 Pro system snapshot
# Usage: sysinfo

BOLD=$'\033[1m'
CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
BLUE=$'\033[0;34m'
RESET=$'\033[0m'

header() { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
kv() { printf "  ${BOLD}%-18s${RESET} %s\n" "$1" "$2"; }

echo -e "${BLUE}${BOLD}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║  OnePlus 7 Pro GM1913 — Ubuntu 24.04 LTS     ║"
echo "  ║  Snapdragon 855 (SM8150) | aarch64            ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${RESET}"

header "SYSTEM"
kv "Hostname:" "$(hostname)"
kv "Kernel:" "$(uname -r)"
kv "OS:" "$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY | cut -d= -f2 | tr -d '"')"
kv "Uptime:" "$(uptime -p 2>/dev/null)"
kv "Date:" "$(date '+%Y-%m-%d %H:%M:%S')"

header "CPU"
CPUFREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
[ -n "$CPUFREQ" ] && kv "Freq (core0):" "$((CPUFREQ/1000)) MHz"
kv "Cores:" "$(nproc) active / 8 total (1×2.84GHz + 3×2.42GHz + 4×1.78GHz)"
kv "Load avg:" "$(cat /proc/loadavg | awk '{print $1, $2, $3}')"

header "MEMORY"
MEM=$(free -h | grep Mem)
kv "Total:"     "$(echo "$MEM" | awk '{print $2}')"
kv "Used:"      "$(echo "$MEM" | awk '{print $3}')"
kv "Available:" "$(echo "$MEM" | awk '{print $7}')"
SWAP=$(free -h | grep Swap)
kv "Swap:" "$(echo "$SWAP" | awk '{print $3}') / $(echo "$SWAP" | awk '{print $2}')"

header "BATTERY"
BAT_CAP=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
BAT_STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
[ -n "$BAT_CAP" ] && kv "Charge:" "${BAT_CAP}% (${BAT_STATUS})"

header "STORAGE"
mount | grep "dm-1" | awk '{printf "  %-18s %s\n", $1, $3}' 2>/dev/null

header "SERVICES"
redis-cli ping > /dev/null 2>&1 && kv "Redis:" "${GREEN}running${RESET}" || kv "Redis:" "${RED}stopped${RESET}"
curl -s http://127.0.0.1:11434 > /dev/null 2>&1 && kv "Ollama:" "${GREEN}running${RESET}" || kv "Ollama:" "${RED}stopped${RESET}"
docker info > /dev/null 2>&1 && kv "Docker:" "${GREEN}running${RESET}" || kv "Docker:" "${RED}stopped${RESET}"
pgrep -x "Xvnc" > /dev/null 2>&1 && kv "VNC:" "${GREEN}running :1 (port 5901)${RESET}" || kv "VNC:" "${YELLOW}stopped${RESET}"

header "AI MODELS (Ollama)"
ollama list 2>/dev/null | tail -n +2 | while read line; do
    echo "  $line"
done

header "NETWORK"
kv "Local IP:" "$(hostname -I 2>/dev/null | awk '{print $1}')"
kv "Public IP:" "$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo 'unavailable')"

echo ""
