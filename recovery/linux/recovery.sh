#!/bin/bash
# recovery-toolkit.sh — Linux/Windows recovery tools from OnePlus 7 Pro
# Requires: USB-C OTG hub + USB drive with Ventoy

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

banner() {
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║   Recovery Toolkit — OnePlus 7 Pro    ║"
echo "  ║   Ubuntu 24.04 | Magisk Rooted        ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${RESET}"
}

banner

echo "  1) Check connected USB drives"
echo "  2) Mount USB drive"
echo "  3) Clone disk (dd with progress)"
echo "  4) Create disk image"
echo "  5) Restore disk image"
echo "  6) Check/repair filesystem"
echo "  7) Wipe drive (secure erase)"
echo "  8) Windows PE tools (via wimtools)"
echo "  9) GRUB repair instructions"
echo "  10) Network boot server (dnsmasq + tftp)"
echo "  q) Quit"

while true; do
    echo ""
    read -rp "Choice: " choice
    case "$choice" in
        1)
            echo -e "\n${CYAN}Connected block devices:${RESET}"
            lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL 2>/dev/null
            ;;
        2)
            read -rp "Device (e.g. /dev/sda1): " dev
            read -rp "Mount point (e.g. /mnt/usb): " mnt
            mkdir -p "$mnt"
            sudo mount "$dev" "$mnt" && echo -e "${GREEN}Mounted $dev at $mnt${RESET}"
            ;;
        3)
            read -rp "Source device (e.g. /dev/sda): " src
            read -rp "Destination device (e.g. /dev/sdb): " dst
            echo -e "${YELLOW}Cloning $src -> $dst${RESET}"
            sudo dd if="$src" of="$dst" bs=4M status=progress conv=fsync
            sudo sync
            echo -e "${GREEN}Clone complete${RESET}"
            ;;
        4)
            read -rp "Source device (e.g. /dev/sda): " src
            read -rp "Output image name: " img
            echo -e "${CYAN}Creating compressed image...${RESET}"
            sudo dd if="$src" bs=4M status=progress | gzip -9 > "$HOME/tools/recovery/${img}.img.gz"
            echo -e "${GREEN}Image saved: ~/tools/recovery/${img}.img.gz${RESET}"
            ;;
        5)
            read -rp "Image file (.img.gz): " img
            read -rp "Target device (e.g. /dev/sdb): " dst
            echo -e "${YELLOW}WARNING: This will overwrite $dst${RESET}"
            read -rp "Continue? (yes/no): " confirm
            [ "$confirm" = "yes" ] && sudo zcat "$img" | dd of="$dst" bs=4M status=progress conv=fsync
            ;;
        6)
            read -rp "Partition to check (e.g. /dev/sda1): " part
            FSTYPE=$(lsblk -no FSTYPE "$part" 2>/dev/null)
            echo -e "${CYAN}Filesystem type: $FSTYPE${RESET}"
            case "$FSTYPE" in
                ext4|ext3|ext2) sudo e2fsck -f "$part" ;;
                vfat|fat32) sudo fsck.vfat -a "$part" ;;
                ntfs) sudo ntfsfix "$part" ;;
                *) echo "Unknown filesystem. Run: sudo fsck $part" ;;
            esac
            ;;
        7)
            read -rp "Drive to wipe (e.g. /dev/sdb): " dev
            echo -e "${RED}${BOLD}WARNING: This will PERMANENTLY erase $dev${RESET}"
            read -rp "Type ERASE to confirm: " confirm
            [ "$confirm" = "ERASE" ] && sudo shred -v -n 1 "$dev" && echo -e "${GREEN}Wipe complete${RESET}"
            ;;
        8)
            echo -e "${CYAN}Windows PE / WIM tools:${RESET}"
            echo "  Install: sudo apt install wimtools"
            echo "  Mount WIM: sudo wimlib-imagex mount <wim> <index> <mountpoint>"
            echo "  List images: sudo wimlib-imagex info <wim>"
            ;;
        9)
            echo -e "${CYAN}GRUB Repair steps:${RESET}"
            echo "  1. Boot from Ubuntu live USB (via Ventoy)"
            echo "  2. Mount broken system: sudo mount /dev/sdaX /mnt"
            echo "  3. Chroot: sudo chroot /mnt"
            echo "  4. Reinstall GRUB: grub-install /dev/sda && update-grub"
            echo "  5. Exit: exit && sudo reboot"
            ;;
        10)
            echo -e "${CYAN}Network boot server (PXE):${RESET}"
            echo "  Requirements: dnsmasq, tftp-hpa, pxelinux"
            echo "  Install: sudo apt install dnsmasq tftpd-hpa pxelinux syslinux"
            echo "  Config: /etc/dnsmasq.conf"
            echo "  TFTP root: /var/lib/tftpboot/"
            echo "  See ~/docs/pxe-setup.md for full instructions"
            ;;
        q|Q) break ;;
        *) echo "Invalid choice" ;;
    esac
done
