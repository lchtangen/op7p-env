# ltangen — OnePlus 7 Pro GM1913 Development Environment

**Device:** OnePlus 7 Pro GM1913 EU
**SoC:** Qualcomm Snapdragon 855 (SM8150) — aarch64
**RAM:** 12 GB LPDDR4X | **Storage:** 256 GB UFS 3.0
**Kernel:** 4.14.180-perf+ (Android / Qualcomm CAF fork, Linux 4.14)
**OS:** Ubuntu 24.04.4 LTS Noble Numbat (chroot on Android kernel)
**Root:** Magisk (Android-side) — chroot has no root capabilities (see docs/android/)

---

## Directory Structure

```
~/
├── ai/             AI agents, Ollama model configs, system prompts library
├── dev/            Development scripts — Linux, Android, Windows tooling
├── docs/           Platform documentation — android, arm64, linux, windows, samplemind
├── projects/       Git repositories (GitHub: lchtangen)
├── recovery/       Recovery tools — bootable USB, Linux/Windows/Android repair
├── workspace/      Active scratch work and experiments
├── backups/        System, config, and data backups
├── README.md       This file — environment overview and quick reference
└── ROADMAP.md      Development roadmap — phases, status, platforms, keypoints
```

---

## Installed Stack

| Tool | Version | Path |
|------|---------|------|
| Ubuntu | 24.04.4 LTS Noble | chroot on Android 4.14 kernel |
| Go | 1.26.1 | `/usr/local/go/bin/go` |
| Rust / rustc | 1.94.0 | `~/.cargo/bin/rustc` (rustup) |
| Node.js | 24.14.0 | `~/.nvm/versions/node/v24.14.0/` |
| Python | 3.12.3 | `/usr/bin/python3` |
| Ollama | 0.18.0 | `/usr/local/bin/ollama` |
| Docker Engine | 29.3.0 | VFS storage driver (overlay2 pending root) |
| kubectl | v1.35.2 | `/usr/local/bin/kubectl` |
| Helm | v3.20.1 | `/usr/local/bin/helm` |
| Terraform | v1.14.7 | `/usr/local/bin/terraform` |
| k9s | v0.50.18 | `~/.local/bin/k9s` |
| Neovim | 0.11.6 | `/usr/bin/nvim` |
| tmux | 3.4 | `/usr/bin/tmux` |
| lazygit | 0.60.0 | `~/.local/bin/lazygit` |

---

## AI Models (Ollama — local inference)

| Model | Size | Use case |
|-------|------|---------|
| `qwen2.5-coder:7b` | 4.7 GB | Code generation, review, debug — primary |
| `llama3.2:3b` | 2.0 GB | General chat, reasoning |
| `smollm2:135m` | 270 MB | Fast completions, testing, low-memory |

Ollama CPU affinity: cores 4–7 (MID + PRIME clusters, 2.4–2.84 GHz)
See: `~/.config/ollama/env` | Docs: `~/docs/android/op7p-environment.md`

---

## Quick Commands

```bash
# System
sysinfo                  # Device snapshot: CPU, RAM, GPU, storage, network
perf-status              # Kernel tuning status (governors, I/O scheduler, GPU)
perf-tune --balanced     # Apply performance tuning (requires root via Termux su)
upgrade --check          # Show all installed tool versions
upgrade --all            # Upgrade Go, Rust, Python stack
env-check                # Validate full dev environment (tools, services, AI, paths)

# AI — local Ollama inference
ai-chat                  # Ollama interactive chat (qwen2.5-coder:7b default)
ai-chat fast             # smollm2:135m (instant)
ai-chat --system "$(cat ~/ai/prompts/go-developer.md)"  # with specialist prompt
review <file>            # AI code review via Ollama
explain <file>           # AI code explanation
ai-commit                # AI-powered git commit message (staged diff)
ai-fix <file>            # AI code fixer — shows unified diff of suggested fixes
ai-fix <file> --apply    # AI code fixer — apply fixes directly

# Navigation
ta                       # tmux attach or create new session
cc                       # Claude Code (claude --dangerously-skip-permissions)
proj                     # cd ~/projects
dev                      # cd ~/dev
ai                       # cd ~/ai

# Config
ezsh                     # edit ~/.zshrc
etmux                    # edit ~/.config/tmux/tmux.conf
envim                    # edit ~/.config/nvim/init.lua
esys                     # edit /etc/zsh/zshrc.local (root)

# VNC desktop
vnc1080                  # Start XFCE4 at 1080p on :1 (port 5901)
vncstop                  # Stop VNC server

# MCP / Claude tools
mcp-setup --install      # Install MCP servers (filesystem, git, sqlite, fetch)
mcp-setup --status       # Check MCP configuration

# Recovery
bootable                 # Create Ventoy bootable USB
recover                  # Recovery toolkit menu
git-setup                # GitHub CLI + SSH key setup
```

---

## Shell Environment

| Item | Value |
|------|-------|
| Shell | zsh 5.9 + Oh My Zsh (robbyrussell) |
| User config | `~/.zshrc` |
| System env (all shells) | `/etc/zsh/zshenv` — PATH, GOROOT, CARGO_HOME, NVM_DIR |
| Interactive aliases | `/etc/zsh/zshrc.local` |
| ls | `eza --icons` |
| cat | `bat --paging=never` |
| grep | `rg` (ripgrep) |
| find | `fd` (fdfind) |
| top | `btop` |
| df | `duf` |

tmux prefix: `Ctrl+a` | Neovim leader: `Space` | Plugin managers: TPM / lazy.nvim

---

## Root Access — Chroot Limitation

The Ubuntu chroot has **no effective capabilities** (`CapEff: 0`).
`sudo` fails — the Android kernel blocks `setgroups()`.

**For kernel tuning (I/O, VM, CPU, GPU):** run from Termux with Magisk `su`:
```bash
# In Termux:
su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced"
```

Full workflow: `~/docs/android/op7p-environment.md`

---

## Services (auto-start on interactive login)

| Service | Address | Notes |
|---------|---------|-------|
| Ollama | 127.0.0.1:11434 | AI inference — started by zshrc.local |
| Redis | 127.0.0.1:6379 | Cache / queue |
| Docker | dockerd | Containers (VFS driver) |
| VNC | :1 / port 5901 | XFCE4 desktop — manual start with `vnc1080` |

---

## Key References

| Topic | File |
|-------|------|
| Roadmap & status | `~/ROADMAP.md` |
| SM8150 hardware reference | `~/docs/arm64/sm8150-hardware.md` |
| OP7P Ubuntu environment | `~/docs/android/op7p-environment.md` |
| Custom kernel guide | `~/docs/android/kernel-custom.md` |
| Magisk & root workflow | `~/docs/android/magisk-root.md` |
| ARM64 toolchain | `~/docs/arm64/README.md` |
| AI models reference | `~/ai/models/README.md` |
| AI agents index | `~/ai/agents/README.md` |
| AI prompt library | `~/ai/prompts/README.md` |
| AI workflow patterns | `~/ai/workflows/README.md` |
| SampleMind project | `~/docs/samplemind/samplemind-dev-setup.md` |

---

*Device: GM1913 EU | Kernel base: 4.14.180-perf+ | Last updated: 2026-03-17*
