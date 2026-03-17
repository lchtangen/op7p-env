#!/bin/bash
# k3s-install.sh — Lightweight Kubernetes for OnePlus 7 Pro (ARM64)
# k3s = production-grade Kubernetes, 50MB binary, works in chroot
# Usage: bash k3s-install.sh [--install|--uninstall|--status|--dashboard]

set -uo pipefail
BOLD=$'\033[1m'; CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; RESET=$'\033[0m'

MODE="${1:---status}"
log()  { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }
info() { echo -e "  $1"; }

check_status() {
    log "k3s Status"
    command -v k3s &>/dev/null && info "k3s: $(k3s --version 2>/dev/null | head -1)" || info "k3s: not installed"
    command -v kubectl &>/dev/null && info "kubectl: $(kubectl version --client -o json 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin)["clientVersion"]["gitVersion"])')" || true
    pgrep -x k3s &>/dev/null && info "Server: running" || info "Server: stopped"
    [ -f /etc/rancher/k3s/k3s.yaml ] && kubectl get nodes 2>/dev/null || info "Cluster: not accessible"
}

install_k3s() {
    log "Installing k3s (ARM64)"
    info "k3s is the lightest production-grade Kubernetes"
    info "Memory footprint: ~500MB (vs ~2GB for full k8s)"
    info ""

    # Install k3s with optimizations for Android chroot environment
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
        --disable traefik \
        --disable servicelb \
        --disable metrics-server \
        --kubelet-arg=allowed-unsafe-sysctls=net.* \
        --kubelet-arg=eviction-hard=memory.available<200Mi \
        --data-dir=/var/lib/rancher/k3s" \
        K3S_KUBECONFIG_MODE="644" \
        sh - 2>&1

    ok "k3s installed"

    # Set up kubectl config
    mkdir -p ~/.kube
    [ -f /etc/rancher/k3s/k3s.yaml ] && cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && chmod 600 ~/.kube/config
    ok "kubeconfig: ~/.kube/config"

    # Install Helm chart repos
    helm repo add stable       https://charts.helm.sh/stable        2>/dev/null && ok "Helm: stable repo"
    helm repo add bitnami      https://charts.bitnami.com/bitnami   2>/dev/null && ok "Helm: bitnami repo"
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null && ok "Helm: ingress-nginx repo"
    helm repo update 2>/dev/null

    echo ""
    info "Essential k8s commands:"
    info "  kubectl get nodes        # cluster status"
    info "  kubectl get all -A       # all resources"
    info "  k9s                      # TUI dashboard"
    info "  helm install <name> bitnami/<chart>"
}

show_dashboard() {
    log "k9s TUI Dashboard"
    command -v k9s &>/dev/null || { warn "k9s not found — run: sudo apt install k9s"; exit 1; }
    export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
    k9s
}

case "$MODE" in
    --install)   install_k3s ;;
    --uninstall) /usr/local/bin/k3s-uninstall.sh 2>/dev/null && ok "k3s removed" || warn "k3s not installed" ;;
    --status)    check_status ;;
    --dashboard) show_dashboard ;;
    *)
        info "Usage: k3s-install.sh [--install|--uninstall|--status|--dashboard]"
        check_status
        ;;
esac
