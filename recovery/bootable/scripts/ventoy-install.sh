#!/bin/bash
# create-ventoy-usb.sh — Install Ventoy to USB drive for bootable multi-ISO
# OnePlus 7 Pro: USB-C OTG required, or use when connected to PC via ADB
# Usage: sudo ./create-ventoy-usb.sh /dev/sdX

set -e
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

DEVICE="${1:-}"

if [ -z "$DEVICE" ]; then
    echo -e "${RED}Usage: sudo $0 /dev/sdX${RESET}"
    echo -e "\nAvailable block devices:"
    lsblk -d -o NAME,SIZE,TYPE,MODEL 2>/dev/null
    exit 1
fi

if [ ! -b "$DEVICE" ]; then
    echo -e "${RED}Error: $DEVICE is not a block device${RESET}"
    exit 1
fi

echo -e "${YELLOW}${BOLD}WARNING: This will ERASE all data on $DEVICE${RESET}"
lsblk "$DEVICE" 2>/dev/null
echo -n "Continue? (yes/no): "
read -r CONFIRM
[ "$CONFIRM" != "yes" ] && echo "Aborted." && exit 0

# Check if Ventoy is installed
if ! command -v ventoy &>/dev/null; then
    echo -e "${CYAN}Installing Ventoy...${RESET}"
    VENTOY_VER=$(curl -s https://api.github.com/repos/ventoy/Ventoy/releases/latest | grep tag_name | cut -d'"' -f4)
    VENTOY_URL="https://github.com/ventoy/Ventoy/releases/download/${VENTOY_VER}/ventoy-${VENTOY_VER#v}-linux-aarch64.tar.gz"
    curl -L "$VENTOY_URL" -o /tmp/ventoy.tar.gz
    tar -xzf /tmp/ventoy.tar.gz -C /tmp/
    cp /tmp/ventoy-*/ventoy /usr/local/bin/ventoy
    chmod +x /usr/local/bin/ventoy
    rm -rf /tmp/ventoy*
fi

echo -e "${CYAN}Installing Ventoy to $DEVICE...${RESET}"
ventoy -I "$DEVICE"

echo -e "\n${GREEN}${BOLD}Ventoy installed!${RESET}"
echo -e "Mount the Ventoy partition and copy ISO files to it."
echo -e "Supported ISOs: Ubuntu, Kali, Parrot, Tails, Windows 11, etc."
echo -e "\nISO directory: ${BOLD}~/bootable/iso/${RESET}"
echo -e "Copy ISOs: ${BOLD}cp ~/bootable/iso/*.iso /mnt/ventoy/${RESET}"
