#!/bin/bash
# download-isos.sh — Download Linux/Windows ISOs for bootable USB
# ARM64 device: uses torrent or direct download

ISODIR="$HOME/bootable/iso"
mkdir -p "$ISODIR"

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}ISO Download Manager${RESET}"
echo "ISOs will be saved to: $ISODIR"
echo ""
echo "Select ISOs to download (amd64 for PC bootable USB):"
echo "  1) Ubuntu 24.04.2 LTS Desktop (amd64)"
echo "  2) Kali Linux 2024.4 (amd64, live)"
echo "  3) Parrot OS 6.2 Security (amd64)"
echo "  4) Tails 6.4 (amd64, amnesic)"
echo "  5) Debian 12.5 (amd64)"
echo "  6) Fedora 41 Workstation (amd64)"
echo "  7) Windows 11 ARM64 (requires Microsoft account - manual)"
echo "  q) Quit"
echo ""

while true; do
    read -rp "Enter choice (1-7, q): " choice
    case "$choice" in
        1)
            echo -e "${CYAN}Downloading Ubuntu 24.04.2 LTS...${RESET}"
            wget -c -P "$ISODIR" "https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso"
            ;;
        2)
            echo -e "${CYAN}Downloading Kali Linux 2024.4...${RESET}"
            wget -c -P "$ISODIR" "https://cdimage.kali.org/kali-2024.4/kali-linux-2024.4-live-amd64.iso"
            ;;
        3)
            echo -e "${CYAN}Downloading Parrot OS 6.2 Security...${RESET}"
            wget -c -P "$ISODIR" "https://deb.parrot.sh/parrot/iso/6.2/Parrot-security-6.2_amd64.iso"
            ;;
        4)
            echo -e "${CYAN}Downloading Tails 6.4...${RESET}"
            wget -c -P "$ISODIR" "https://tails.net/torrents/files/tails-amd64-6.4.iso"
            ;;
        5)
            echo -e "${CYAN}Downloading Debian 12.5...${RESET}"
            wget -c -P "$ISODIR" "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
            ;;
        6)
            echo -e "${CYAN}Downloading Fedora 41 Workstation...${RESET}"
            wget -c -P "$ISODIR" "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-41-1.4.iso"
            ;;
        7)
            echo -e "${YELLOW}Windows 11 must be downloaded from: https://www.microsoft.com/software-download/windows11${RESET}"
            echo -e "Use Rufus or Ventoy on PC, or download the ISO directly."
            ;;
        q|Q) break ;;
        *) echo "Invalid choice" ;;
    esac
done

echo -e "\n${GREEN}Downloaded ISOs:${RESET}"
ls -lh "$ISODIR"/*.iso 2>/dev/null || echo "No ISOs in $ISODIR"
