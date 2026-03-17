# CLAUDE.md — ltangen Dev Environment Context

This file gives Claude Code accurate context about this environment.

---

## Hardware

| Item | Value |
|------|-------|
| Device | OnePlus 7 Pro GM1913 EU |
| SoC | Qualcomm SM8150 (Snapdragon 855), aarch64 |
| CPU | 1×2.84GHz Prime + 3×2.42GHz MID + 4×1.79GHz LITTLE |
| RAM | 12 GB LPDDR4X + 4 GB swap |
| Storage | 256 GB UFS 3.0 |
| Kernel | 4.14.180-perf+ (Android/Qualcomm CAF fork) |
| OS | Ubuntu 24.04.4 LTS Noble Numbat (chroot on Android) |

---

## Critical Constraints

- **No root in chroot:** CapEff=0. `sudo` fails. Never suggest `sudo` for runtime ops.
  - Exception: aliases like `sudo apt` work if only `setgroups` is the issue; test first.
  - Sysfs/kernel tuning must run from **Termux** with Magisk `su`.
- **Android kernel 4.14:** Missing BBR, zstd zram, BFQ I/O, io_uring, KVM.
  - Do not suggest features requiring kernel ≥ 5.x or Linux-only modules.
- **ARM64 only (aarch64):** No x86 binaries. Always use ARM64 downloads/builds.
- **Chroot, not VM:** No hardware virtualization. Container isolation is limited.
- **Docker uses VFS driver:** Slow. overlay2 blocked on root access.

---

## Installed Tool Versions (verified 2026-03-17)

| Tool | Version |
|------|---------|
| Go | 1.26.1 |
| Rust / rustc | 1.94.0 (rustup) |
| Node.js | v24.14.0 (nvm) |
| Python | 3.12.3 |
| Neovim | 0.11.6 (LuaJIT, lazy.nvim) |
| tmux | 3.4 |
| Docker | 29.3.0 (VFS) |
| kubectl | v1.35.2 |
| Helm | v3.20.1 |
| Terraform | v1.14.7 |
| k9s | v0.50.18 |
| lazygit | 0.60.0 |
| Ollama | 0.18.0 |
| GitHub CLI | 2.88.1 (needs auth) |
| zsh | 5.9 + Oh My Zsh (robbyrussell) |

---

## Directory Layout (all lowercase)

```
~/ai/           agents/ datasets/ models/ notebooks/ prompts/ workflows/
~/dev/          dotfiles/ scripts/{android,linux,windows}/ snippets/ templates/
~/docs/         android/ arm64/ linux/ notes/ samplemind/ windows/
~/recovery/     android/ bootable/scripts/ linux/ windows/
~/projects/     (repos — not yet cloned)
~/workspace/    (scratch)
~/backups/      configs/ databases/ dotfiles/ snapshots/
```

- **Dirs:** always lowercase
- **Scripts:** kebab-case (`perf-tune.sh`, `git-setup.sh`)
- **Meta docs:** UPPERCASE.md (`README.md`, `ROADMAP.md`, `CLAUDE.md`)

---

## Shell Config Files

| File | Purpose |
|------|---------|
| `/etc/zsh/zshenv` | PATH, GOROOT, CARGO_HOME, NVM_DIR — all zsh instances |
| `/etc/zsh/zshrc.local` | Aliases, plugins, service autostart — interactive only |
| `~/.zshrc` | OMZ, user env vars, alias overrides, login banner |

**Note:** `/etc/zsh/zshrc.local` currently has broken aliases (capitalized paths).
Override block in `~/.zshrc` corrects them at runtime. Permanent fix pending Termux root:
```bash
su -c "bash /storage/emulated/0/dev/scripts/android/fix-zshrc-aliases.sh"
```

---

## Key Aliases

| Alias | Command |
|-------|---------|
| `cc` | `claude` |
| `ccc` | `claude --continue` |
| `ai` | `cd ~/ai` |
| `dev` | `cd ~/dev` |
| `proj` | `cd ~/projects` |
| `ta` | tmux attach or new session |
| `lg` | lazygit |
| `ai-code` | `ollama run qwen2.5-coder:7b` |
| `ai-chat` | `ollama run llama3.2:3b` |

---

## Services (auto-start on interactive login)

| Service | Endpoint |
|---------|---------|
| Ollama | 127.0.0.1:11434 |
| Redis | 127.0.0.1:6379 |
| Docker | dockerd (VFS) |

---

## Pending (requires Termux root)

```bash
# From Termux with Magisk su:
su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced"
su -c "bash /storage/emulated/0/dev/scripts/linux/docker-optimize.sh"
su -c "bash /storage/emulated/0/dev/scripts/linux/ollama-config.sh --apply"
su -c "bash /storage/emulated/0/dev/scripts/android/fix-zshrc-aliases.sh"
```

No root needed:
```bash
gh auth login
gh repo clone lchtangen/samplemind-ai ~/projects/samplemind-ai
```
