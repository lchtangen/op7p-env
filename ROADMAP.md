# ROADMAP — ltangen Development Environment

**Device:** OnePlus 7 Pro GM1913 EU | Snapdragon 855 (SM8150) | aarch64
**Base:** Ubuntu 24.04.4 LTS (chroot) on Android 4.14.180-perf+
**Last updated:** 2026-03-17

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Complete |
| 🔄 | In progress |
| ⏳ | Pending — ready to execute |
| 🔒 | Blocked (requires root / physical action) |
| 📋 | Planned — needs work |

---

## Phase 1 — Foundation (Ubuntu on Android) ✅

| Item | Status | Notes |
|------|--------|-------|
| Ubuntu 24.04.4 chroot installed | ✅ | Noble Numbat, aarch64 |
| zsh + Oh My Zsh configured | ✅ | robbyrussell, `/etc/zsh/zshenv` + `~/.zshrc` |
| PATH resolved correctly (Go, Rust, Node, cargo) | ✅ | `/etc/zsh/zshenv` — all shells |
| bat / fd symlinks (`~/.local/bin/`) | ✅ | Fix for Ubuntu batcat/fdfind naming |
| Neovim 0.11.6 + lazy.nvim + LSP | ✅ | pyright, gopls, ts_ls, lua_ls, bashls |
| tmux 3.4 + TPM (resurrect, continuum) | ✅ | Prefix: Ctrl+a, Catppuccin status bar |
| VNC + XFCE4 desktop (1080p :1) | ✅ | Port 5901 |
| Docker 29.3.0 | ✅ | VFS storage driver (overlay2 pending) |
| Ollama 0.18.0 + 3 models | ✅ | qwen2.5-coder:7b, llama3.2:3b, smollm2:135m |
| Directory structure (lowercase, native Linux) | ✅ | ai/ dev/ docs/ recovery/ projects/ |
| README.md + ROADMAP.md at home root | ✅ | This file |

---

## Phase 2 — Performance Tuning 🔄

| Item | Status | Notes |
|------|--------|-------|
| Go 1.26.1 upgraded | ✅ | `~/.local/lib/go/` → `/usr/local/go` symlinked |
| Rust 1.94.0 via rustup | ✅ | `~/.cargo/bin/rustc` — PATH takes priority over apt |
| Node.js 24.14.0 via nvm | ✅ | |
| `perf-tune.sh` written (native Linux config files) | ✅ | `/etc/sysctl.d/`, udev rules, systemd service |
| `perf-tune-android.sh` for Termux root | ✅ | Applies sysfs + writes into chroot |
| VM sysctl applied (swappiness=20, dirty=30) | 🔒 | Needs: `su` from Termux → run perf-tune-android.sh |
| I/O scheduler: cfq → deadline (UFS 3.0) | 🔒 | Needs: Termux root |
| WALT thresholds (sched_upmigrate 80/80) | 🔒 | Needs: Termux root |
| GPU Adreno 640v2 balanced (default_pwrlevel=2) | 🔒 | Needs: Termux root |
| Docker: VFS → overlay2 | 🔒 | Needs: Termux root — `docker-optimize.sh` |
| Ollama CPU affinity (cores 4–7) | 🔒 | Needs: systemd from root — `ollama-config.sh --apply` |
| `/etc/sysctl.d/99-perf-*.conf` persistent config | 🔒 | Written by `perf-tune.sh` when run as root |
| `/etc/udev/rules.d/60-io-scheduler.rules` | 🔒 | Written by `perf-tune.sh` when run as root |

**Unblock all 🔒 items with:**
```bash
# In Termux with Magisk su:
su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced"
```

---

## Phase 3 — Infrastructure & Orchestration 🔄

| Item | Status | Notes |
|------|--------|-------|
| kubectl v1.35.2 | ✅ | |
| Helm v3.20.1 | ✅ | |
| k9s v0.50.18 | ✅ | TUI Kubernetes dashboard |
| Terraform v1.14.7 | ✅ | |
| k3s lightweight Kubernetes | ⏳ | Script ready: `dev/scripts/linux/k3s-install.sh --install` |
| Docker overlay2 storage | 🔒 | `docker-optimize.sh` — needs root |
| GitHub CLI (gh) 2.88.1 installed | ✅ | Needs `gh auth login` to authenticate |
| SampleMind repo cloned | ⏳ | `gh repo clone lchtangen/samplemind-ai ~/projects/` |
| JupyterLab configured | 📋 | For AI/ML notebook work |
| Zram with zstd compression | 🔒 | Requires custom kernel (zstd not in 4.14-perf+) |

---

## Phase 4 — Custom Kernel 🔒

> **Requires physical device action: TWRP + fastboot**
> Risk: Medium — have full OxygenOS backup before flashing

| Item | Status | Notes |
|------|--------|-------|
| TWRP installed | ✅ | Required for kernel flash |
| OxygenOS full backup | ⏳ | `adb backup` or TWRP → Backup all partitions |
| Download Kirisakura-NG kernel | ⏳ | `https://github.com/freak07/Kirisakura_OP7Pro` |
| Flash kernel via Magisk or TWRP | 🔒 | Physical device action |
| Verify new kernel version | 🔒 | `uname -r` after flash |
| Enable zstd zram (post-flash) | 🔒 | `dev/scripts/linux/ollama-config.sh` |
| Apply BFQ/mq-deadline I/O scheduler | 🔒 | Available only on custom kernel |
| BBR TCP congestion (kernel module) | 🔒 | Not available on 4.14-perf+ stock |

**Custom kernel unlocks:** zstd zram, BFQ I/O, BBR TCP, GPU OC/UV, wakelock control, LLVM-compiled ARM64

Guide: `~/docs/android/kernel-custom.md`

---

## Phase 5 — AI & Development Platform 📋

| Item | Status | Notes |
|------|--------|-------|
| Ollama optimized for SM8150 | 🔄 | Config written, systemd patch needs root |
| anthropic / openai Python packages | ✅ | Installed via pip3 |
| langchain + fastapi + uvicorn | ✅ | |
| Hugging Face hub | ✅ | |
| JupyterLab | ✅ | Installed, not configured for persistent launch |
| Claude Code (claude CLI) | ✅ | `cc` alias |
| SampleMind AI engine | 📋 | Hermes + OpenVINO (ARM64 build needed) |
| SampleMind frontend (Next.js + Tauri) | 📋 | Repo clone + build |
| OpenVINO ARM64 build | 📋 | Intel OpenVINO for ARM — experimental |
| Additional Ollama models | ⏳ | `ollama pull llama3.1:8b` (4.7GB) |

---

## Phase 6 — Bootable USB & Multi-Distro 📋

| Item | Status | Notes |
|------|--------|-------|
| Ventoy install script | ✅ | `recovery/bootable/scripts/ventoy-install.sh` |
| ISO download script | ✅ | `recovery/bootable/scripts/iso-fetch.sh` |
| ISOs downloaded | ⏳ | Ubuntu, Kali, Parted, Debian, Win11 ARM64 |
| Ventoy persistence config | 📋 | `ventoy.json` for Ubuntu persistence |
| Windows 11 ARM64 ISO | 📋 | For PC recovery |
| Kali Linux portable pentest | 📋 | With persistence partition |

---

## Phase 7 — Multi-Platform Support 📋

| Platform | Status | Notes |
|----------|--------|-------|
| OnePlus 7 Pro (primary) | 🔄 | Phases 1–5 active |
| HP EliteBook 840 G9 (Ubuntu 24.04 native) | 📋 | Docs: `docs/linux/elitebook-dualboot.md` |
| ThinkPad X1 Carbon G8 (WSL2 + Win11) | 📋 | Docs: `docs/windows/thinkpad-wsl2-setup.md` |
| Bootable USB (Ventoy, all PCs) | 📋 | Phase 6 |
| ARM64 cross-compile toolchain | 📋 | Docs: `docs/arm64/README.md` |

---

## Pending Actions — Immediate

Execute in order from **Termux** with Magisk root:

```bash
# 1. Apply kernel/sysfs performance tuning (unblocks Phase 2)
su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced"

# 2. Apply Docker overlay2 (no images to migrate — safe now)
su -c "bash /storage/emulated/0/dev/scripts/linux/docker-optimize.sh"

# 3. Apply Ollama CPU affinity
su -c "bash /storage/emulated/0/dev/scripts/linux/ollama-config.sh --apply"
```

Then from Ubuntu chroot (no root needed):
```bash
# 4. Authenticate GitHub CLI (already installed)
gh auth login

# 5. Clone SampleMind repo
gh repo clone lchtangen/samplemind-ai ~/projects/samplemind-ai

# 6. First nvim launch — install plugins
nvim +":Lazy sync" +qa

# 7. Install TPM plugins in tmux
# Open tmux → Ctrl+a + I
```

---

## Architecture Notes

### SM8150 CPU Cluster Layout
```
LITTLE  cpu0–3   Kryo 485 Silver  1785.6 MHz  (efficiency, OS/Android)
MID     cpu4–6   Kryo 485 Gold    2419.2 MHz  (balanced workloads)
PRIME   cpu7     Kryo 485 Gold+   2841.6 MHz  (peak single-thread)
GPU     Adreno 640v2              585 MHz max  (5 power levels)
```

### Chroot vs Native Linux Limits
- No KVM — VM acceleration not available
- No kernel module loading from chroot
- sudo blocked (no CapEff) — all sysfs tuning via Termux su
- Android kernel 4.14 missing: BBR, zstd zram, BFQ I/O, io_uring
- Mainline Linux 6.x: partial SM8150 support — not daily-use ready until ~2026–2027

### Native Linux Config File Locations
```
/etc/sysctl.d/99-perf-vm.conf      VM tuning (swappiness, dirty ratios)
/etc/sysctl.d/99-perf-net.conf     Network buffers
/etc/udev/rules.d/60-io-scheduler.rules    I/O scheduler at device registration
/etc/systemd/system/perf-tune.service      CPU/GPU tuning at boot
/etc/docker/daemon.json             Docker daemon config
/etc/systemd/system/ollama.service  Ollama service with CPU affinity
/etc/zsh/zshenv                     All-shell PATH and env vars
/etc/zsh/zshrc.local                Interactive aliases and service autostart
```

---

*Device: GM1913 EU | Kernel: 4.14.180-perf+ | Last updated: 2026-03-17*
