#!/bin/bash
# vnc-desktop.sh — VNC desktop management for OnePlus 7 Pro Ubuntu chroot
# Starts/stops/restarts an XFCE4 desktop via Xvfb + x11vnc or TigerVNC
# Usage: vnc-desktop.sh [start|stop|restart|status]
#
# Clients connect via: VNC viewer → device-ip:5901
# ADB tunnel (no WiFi needed): adb forward tcp:5901 tcp:5901 → localhost:5901

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET='\033[0m'

log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
err()  { echo -e "${RED}  ✗ $1${RESET}"; exit 1; }

DISPLAY_NUM=":1"
VNC_PORT=5901
GEOMETRY="1920x1080"
DEPTH=24
VNC_LOG="/tmp/vnc-desktop.log"

MODE="${1:-status}"

check_deps() {
    local missing=()
    command -v Xvnc   &>/dev/null || command -v vncserver &>/dev/null || missing+=("tigervnc-standalone-server")
    command -v startxfce4 &>/dev/null || missing+=("xfce4")
    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing packages: ${missing[*]}"
        warn "Install with: apt install ${missing[*]}"
        warn "Note: apt may require root — run from Termux su if needed"
        return 1
    fi
    return 0
}

show_status() {
    log "VNC Desktop Status"
    if pgrep -x "Xvnc" > /dev/null 2>&1 || pgrep -x "Xtigervnc" > /dev/null 2>&1; then
        echo -e "  Status:   ${GREEN}running${RESET}"
        echo -e "  Display:  $DISPLAY_NUM"
        echo -e "  Port:     $VNC_PORT"
        echo -e "  Connect:"
        echo -e "    Direct VNC:     device-ip:$VNC_PORT"
        echo -e "    ADB tunnel:     adb forward tcp:$VNC_PORT tcp:$VNC_PORT → vnc://localhost:$VNC_PORT"
        pgrep -a "Xvnc\|Xtigervnc" | head -3 | sed 's/^/  PID: /'
    else
        echo -e "  Status:   ${YELLOW}stopped${RESET}"
        echo -e "  Start:    vnc1080  or  bash $0 start"
    fi
}

start_vnc() {
    if pgrep -x "Xvnc" > /dev/null 2>&1 || pgrep -x "Xtigervnc" > /dev/null 2>&1; then
        warn "VNC already running on display $DISPLAY_NUM"
        show_status
        return
    fi

    check_deps || return 1

    log "Starting XFCE4 VNC desktop (${GEOMETRY})"

    # Set VNC password if not already set
    if [ ! -f "$HOME/.vnc/passwd" ]; then
        warn "No VNC password set. Set one now:"
        vncpasswd
    fi

    # Start TigerVNC server with XFCE4
    vncserver "$DISPLAY_NUM" \
        -geometry "$GEOMETRY" \
        -depth "$DEPTH" \
        -localhost no \
        -SecurityTypes VncAuth \
        > "$VNC_LOG" 2>&1 &

    sleep 2

    if pgrep -x "Xvnc\|Xtigervnc" > /dev/null 2>&1; then
        ok "VNC desktop started on display $DISPLAY_NUM (port $VNC_PORT)"
        ok "Geometry: $GEOMETRY"
        echo ""
        echo -e "  Connect with VNC viewer to: ${BOLD}device-ip:$VNC_PORT${RESET}"
        echo -e "  ADB tunnel: ${CYAN}adb forward tcp:$VNC_PORT tcp:$VNC_PORT${RESET}"
        echo -e "  Logs: $VNC_LOG"
    else
        err "VNC failed to start. Check: cat $VNC_LOG"
    fi
}

stop_vnc() {
    log "Stopping VNC desktop"
    if command -v vncserver &>/dev/null; then
        vncserver -kill "$DISPLAY_NUM" > /dev/null 2>&1 || true
    fi
    pkill -x "Xvnc"     2>/dev/null || true
    pkill -x "Xtigervnc" 2>/dev/null || true
    pkill -f "startxfce4" 2>/dev/null || true
    sleep 1
    pgrep -x "Xvnc\|Xtigervnc" > /dev/null 2>&1 \
        && warn "VNC still running — try: pkill -9 Xvnc" \
        || ok "VNC stopped"
}

case "$MODE" in
    start)   start_vnc ;;
    stop)    stop_vnc ;;
    restart) stop_vnc; sleep 1; start_vnc ;;
    status)  show_status ;;
    *)
        echo "Usage: $0 [start|stop|restart|status]"
        echo "Aliases: vnc1080 (start) | vncstop (stop)"
        show_status
        ;;
esac
