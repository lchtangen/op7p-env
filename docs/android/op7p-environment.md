# op7p-environment.md — Ubuntu on Android: Definitive Guide

OnePlus 7 Pro GM1913 EU — Ubuntu 24.04.4 LTS chroot on Android 4.14 kernel.
This is the primary reference for the development environment on this device.

---

## Architecture Overview

```
Hardware (SM8150 / Snapdragon 855)
└── Android Kernel 4.14.180-perf+ (Qualcomm CAF — NOT replaceable from chroot)
    └── Android 11 (OxygenOS 11)
        ├── Magisk (systemless root, hooks Android init)
        │   └── Magisk modules (LSPosed, etc.)
        └── Termux (Android terminal emulator, ARM64 native)
            └── Ubuntu 24.04.4 chroot / proot-distro
                ├── /home/ltangen/ (user home — on Android storage partition)
                ├── /etc/zsh/zshenv (all-shell env: PATH, GOROOT, etc.)
                ├── /etc/zsh/zshrc.local (interactive: aliases, autostart)
                └── ~/.zshrc (user: OMZ, workspace vars, custom aliases)
```

---

## Chroot vs Native Linux

| Feature | Ubuntu Chroot | Native Linux |
|---------|--------------|-------------|
| Kernel | Android 4.14-perf+ (shared) | Full control |
| Root in Ubuntu | ❌ No (CapEff=0) | ✅ Yes |
| sysfs/proc writes | ❌ Permission denied | ✅ Allowed |
| systemd | ⚠️ Limited (no PID 1) | ✅ Full |
| KVM / virtualisation | ❌ Not supported | ❌ Not on SM8150 |
| GPU compute | ❌ No Vulkan/OpenCL | ❌ No drivers |
| USB OTG | ✅ Via Android | ✅ |
| Networking | ✅ Shares Android network | ✅ |
| File access | ✅ Full Android storage | ✅ |

---

## Shell Environment

### /etc/zsh/zshenv (all zsh instances — login, scripts, LSP daemons)

```bash
GOROOT=/usr/local/go
GOPATH=~/go
CARGO_HOME=~/.cargo
RUSTUP_HOME=~/.rustup
NVM_DIR=~/.nvm
OLLAMA_HOST=127.0.0.1:11434
ANDROID_STORAGE=/mnt/android

# PATH order (critical for correct tool versions):
~/.local/bin      ← bat/fd symlinks (Ubuntu batcat/fdfind fix)
~/bin
~/.cargo/bin      ← Rust 1.94.0 (before /usr/bin/rustc 1.75.0)
~/go/bin
/usr/local/go/bin ← Go 1.26.1
/usr/local/bin
/usr/local/sbin
$JAVA_HOME/bin
/usr/sbin /usr/bin /sbin /bin
~/.nvm/versions/node/vX.Y.Z/bin  ← appended by nvm
```

### /etc/zsh/zshrc.local (interactive shells only)

```bash
# Tool aliases (modern CLI replacements)
ls   → eza --icons
ll   → eza -la --icons --git
cat  → bat --paging=never
grep → rg (ripgrep)
top  → btop
df   → duf

# Auto-start services on login:
_start_services() { redis, ollama, dockerd }
```

### ~/.zshrc (user, loaded after system config)

Oh My Zsh + workspace env vars + custom aliases.

---

## Installed Tools

### Languages

| Tool | Version | Binary | Notes |
|------|---------|--------|-------|
| Go | 1.26.1 | `/usr/local/go/bin/go` | Upgraded from 1.22 |
| Rust | 1.94.0 | `~/.cargo/bin/rustc` | rustup, PATH before apt |
| Node.js | 24.14.0 | `~/.nvm/versions/node/v24.14.0/bin/node` | via nvm |
| Python | 3.12.3 | `/usr/bin/python3` | system |
| Java | 21 | `/usr/lib/jvm/java-21-openjdk-arm64/bin/java` | |

### DevOps

| Tool | Version | Binary |
|------|---------|--------|
| Docker | 29.3.0 | `/usr/bin/dockerd` (VFS — overlay2 pending) |
| kubectl | v1.35.2 | `/usr/local/bin/kubectl` |
| Helm | v3.20.1 | `/usr/local/bin/helm` |
| Terraform | v1.14.7 | `/usr/local/bin/terraform` |
| k9s | v0.50.18 | `~/.local/bin/k9s` |

### Dev Environment

| Tool | Version | Config |
|------|---------|--------|
| Neovim | 0.11.6 | `~/.config/nvim/` (lazy.nvim + LSP) |
| tmux | 3.4 | `~/.config/tmux/tmux.conf` (TPM, Catppuccin) |
| zsh | 5.9 | `/etc/zsh/zshenv` + `~/.zshrc` |
| lazygit | 0.60.0 | `~/.local/bin/lazygit` |
| Claude Code | latest | `cc` alias |

### AI Stack

| Tool | Notes |
|------|-------|
| Ollama 0.18.0 | Local inference server — API at 127.0.0.1:11434 |
| langchain-ollama | LangChain integration for Ollama |
| litellm | Unified LLM API (Ollama + Claude + OpenAI) |
| JupyterLab | Notebooks — `jlab` alias |
| AI agents | `~/ai/agents/` — chat, review, explain, commit, debug, docs, refactor |
| ai-stack.sh | `~/dev/scripts/linux/ai-stack.sh` — stack manager |

---

## Root Access Workflow

### From Ubuntu chroot (no root capabilities)

```bash
# This FAILS — sudo is blocked:
sudo bash dev/scripts/linux/perf-tune.sh --balanced
# Error: su: cannot set groups: Operation not permitted
```

### From Termux with Magisk su (correct approach)

```bash
# Method A — run Android-side script directly:
su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced"

# Method B — enter chroot as root, then run Linux scripts:
su
bash /storage/emulated/0/dev/scripts/android/root-enter.sh
# Now inside chroot as root:
bash /home/ltangen/dev/scripts/linux/perf-tune.sh --balanced
```

### Scripts requiring root (run from Termux su)

| Script | Purpose |
|--------|---------|
| `dev/scripts/android/perf-tune-android.sh` | Full SM8150 kernel tuning |
| `dev/scripts/linux/docker-optimize.sh` | Docker VFS → overlay2 |
| `dev/scripts/linux/ollama-config.sh --apply` | Ollama systemd CPU affinity |
| `dev/scripts/linux/k3s-install.sh` | Install k3s Kubernetes |
| `dev/scripts/linux/perf-tune.sh` | Write Linux config files + apply |

---

## Performance Tuning Status

| Parameter | Default (Android) | Tuned (dev target) | Status |
|-----------|------------------|-------------------|--------|
| vm.swappiness | 160 | 20 | 🔒 Needs root |
| vm.dirty_ratio | 20 | 30 | 🔒 Needs root |
| vm.vfs_cache_pressure | 100 | 50 | 🔒 Needs root |
| I/O scheduler (UFS) | cfq | deadline | 🔒 Needs root |
| CPU governor | schedutil | schedutil + 500µs | 🔒 Needs root |
| WALT upmigrate | 95 95 | 80 80 | 🔒 Needs root |
| GPU default_pwrlevel | 4 | 2 | 🔒 Needs root |
| Docker storage | VFS | overlay2 | 🔒 Needs root |
| TCP CC | cubic | BBR (if available) | 🔒 Needs root |
| Ollama CPU affinity | all cores | cores 4–7 | 🔒 Needs root (systemd) |

---

## VNC Desktop

```bash
vnc1080     # Start XFCE4 at 1920×1080 on display :1 (port 5901)
vncstop     # Stop VNC server

# Connect from PC:
# VNC client → device-ip:5901
# Or via ADB tunnel: adb forward tcp:5901 tcp:5901 → localhost:5901
```

---

## Known Limitations

1. **No root in chroot** — all kernel/sysfs writes via Termux su
2. **No KVM** — no VM acceleration, containers only
3. **No GPU compute** — Adreno 640 has no open Vulkan/OpenCL in chroot
4. **systemd limited** — no PID 1 systemd, service management partial
5. **Android kernel 4.14** — missing BBR, zstd zram, BFQ, io_uring vs mainline
6. **Battery drain** — running Docker + Ollama continuously drains fast
7. **Thermal throttling** — SM8150 throttles above ~80°C; monitor via sysinfo

---

## Maintenance

```bash
sysinfo                    # check system state
perf-status                # check tuning state
upgrade --check            # check tool versions
upgrade --all              # upgrade Go, Rust, Node, Python
upgrade --k8s              # upgrade kubectl, Helm, k9s, Terraform
bash dev/scripts/linux/cleanup.sh          # free space
bash dev/scripts/linux/cleanup.sh --deep   # + docker prune + ollama clean
bash dev/scripts/linux/ai-stack.sh --status   # AI stack status
```
