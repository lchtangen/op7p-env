#!/bin/bash
# fastboot-recovery.sh — OnePlus 7 Pro GM1913 fastboot and ADB recovery
# Run from PC with ADB/fastboot tools installed, device connected via USB
# Usage: bash fastboot-recovery.sh [--status|--flash-stock|--flash-boot <img>|--sideload <zip>]

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
err()  { echo -e "${RED}  ✗ $1${RESET}"; }

MODE="${1:---status}"

check_adb() {
    command -v adb &>/dev/null || { err "adb not found — install android-tools-adb"; exit 1; }
    command -v fastboot &>/dev/null || { err "fastboot not found — install android-tools-fastboot"; exit 1; }
}

show_status() {
    log "Device Status"
    echo "ADB devices:"
    adb devices 2>/dev/null
    echo ""
    echo "Fastboot devices:"
    fastboot devices 2>/dev/null
}

flash_boot() {
    local img="${1:-}"
    [ -z "$img" ] && { err "Usage: $0 --flash-boot <boot.img>"; exit 1; }
    [ -f "$img" ] || { err "File not found: $img"; exit 1; }
    log "Flashing boot partition: $img"
    warn "Device must be in fastboot mode: adb reboot bootloader"
    fastboot flash boot "$img"
    ok "Boot flashed"
    fastboot reboot
    ok "Rebooting..."
}

sideload_zip() {
    local zip="${1:-}"
    [ -z "$zip" ] && { err "Usage: $0 --sideload <update.zip>"; exit 1; }
    [ -f "$zip" ] || { err "File not found: $zip"; exit 1; }
    log "Sideloading OTA: $zip"
    warn "Device must be in TWRP recovery: adb reboot recovery"
    adb sideload "$zip"
    ok "Sideload complete"
}

check_adb

case "$MODE" in
    --status)        show_status ;;
    --flash-stock)
        log "Flashing stock boot image"
        STOCK=$(ls ~/recovery/android/stock-images/boot*.img 2>/dev/null | head -1)
        [ -n "$STOCK" ] && flash_boot "$STOCK" || { warn "No stock boot image found in ~/recovery/android/stock-images/"; exit 1; }
        ;;
    --flash-boot)    flash_boot "${2:-}" ;;
    --sideload)      sideload_zip "${2:-}" ;;
    --reboot-recovery) adb reboot recovery && ok "Rebooting to TWRP recovery" ;;
    --reboot-bootloader) adb reboot bootloader && ok "Rebooting to fastboot" ;;
    *)
        echo "Usage: $0 [--status|--flash-stock|--flash-boot <img>|--sideload <zip>|--reboot-recovery|--reboot-bootloader]"
        show_status
        ;;
esac
