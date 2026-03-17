# dev/scripts/linux/ — Linux / Ubuntu ARM64 Scripts

Scripts for Ubuntu 24.04.4 LTS on aarch64 (OnePlus 7 Pro chroot).
All run as user `ltangen` unless marked **[root]**.

---

## sysinfo.sh

Device and environment snapshot for OnePlus 7 Pro SM8150.

```bash
sysinfo       # alias → bash ~/dev/scripts/linux/sysinfo.sh
```

Output: kernel, uptime, CPU cluster governors + frequencies, RAM/swap usage,
GPU (Adreno 640v2) governor + clock, battery %, storage, Docker, Ollama status.

---

## perf-tune.sh **[root]**

SM8150 performance tuning using **native Linux config files** for persistence.

```bash
perf-status                        # read current state (no root)
sudo bash perf-tune.sh --balanced  # apply balanced mode
sudo bash perf-tune.sh --max       # apply max performance
sudo bash perf-tune.sh --battery   # apply battery saver
sudo bash perf-tune.sh --remove    # remove all config files
```

**Writes:**
- `/etc/sysctl.d/99-perf-vm.conf` — swappiness=20, dirty_ratio=30, vfs_cache_pressure=50
- `/etc/sysctl.d/99-perf-net.conf` — 64 MB buffers, tcp_fastopen
- `/etc/udev/rules.d/60-io-scheduler.rules` — deadline scheduler for UFS 3.0 (sda–sdf)
- `/etc/systemd/system/perf-tune.service` — CPU governor + WALT + GPU at boot

> **Note:** `sudo` is blocked in the Ubuntu chroot. Use `android/perf-tune-android.sh` from Termux instead.

---

## upgrade-stack.sh

Upgrade development tools to latest versions.

```bash
upgrade --check      # show all current versions (no downloads)
upgrade --all        # Go + Rust + Python packages
upgrade --go         # Go only (downloads from go.dev)
upgrade --rust       # Rust only (rustup update stable)
upgrade --python     # Python pip packages (anthropic, langchain, fastapi, etc.)
upgrade --tools      # Helm + k9s + lazygit (ARM64 binaries via GitHub releases)
```

**Go install path:** `~/.local/lib/go/` → `/usr/local/go` (symlinked by root)
**Rust:** `~/.cargo/bin/rustc` — PATH priority set in `/etc/zsh/zshenv`

---

## docker-optimize.sh **[root]**

Migrate Docker from VFS (slow) to overlay2 storage driver.

```bash
sudo bash docker-optimize.sh
```

**Writes:** `/etc/docker/daemon.json` — overlay2, BuildKit enabled, log rotation 10 MB × 3.
**Warning:** VFS → overlay2 requires container/image migration. No images currently = safe.

---

## ollama-config.sh **[root for systemd]**

Optimize Ollama for SM8150 — CPU affinity to MID + PRIME cores (4–7).

```bash
bash ollama-config.sh --status     # show current config and running models
bash ollama-config.sh --bench      # benchmark smollm2:135m inference speed
sudo bash ollama-config.sh --apply # patch systemd service + write env file
```

**Writes:**
- `/etc/systemd/system/ollama.service` — CPUAffinity=4 5 6 7, Nice=-10
- `~/.config/ollama/env` — OLLAMA_NUM_PARALLEL=1, OLLAMA_KEEP_ALIVE=10m

---

## k3s-install.sh **[root]**

Lightweight Kubernetes (~500 MB) for ARM64 — minimal footprint vs full k8s (~2 GB).

```bash
sudo bash k3s-install.sh --install    # install k3s + configure kubectl + Helm repos
sudo bash k3s-install.sh --status     # cluster status
bash k3s-install.sh --dashboard       # launch k9s TUI
sudo bash k3s-install.sh --uninstall  # remove k3s
```

Disables: traefik, servicelb, metrics-server (saves ~150 MB RAM).

---

## git-setup.sh

GitHub CLI + SSH key + global git configuration.

```bash
git-setup     # alias → bash ~/dev/scripts/linux/git-setup.sh
```

Sets: `user.name`, `user.email`, `core.editor=nvim`, `init.defaultBranch=main`.
Generates: `~/.ssh/github_ed25519` SSH key.
Installs: `gh` CLI, runs `gh auth login`.

---

## ubuntu-post-install.sh **[root]**

Fresh Ubuntu chroot first-boot setup — run once after new install.

```bash
sudo bash ubuntu-post-install.sh
```

Installs: build essentials, git, curl, zsh, eza, bat, fd-find, ripgrep, btop, duf, ncdu, tmux, neovim, Docker, kubectl, Helm, Terraform, Ollama.

---

## cleanup.sh

Free disk space and remove stale caches.

```bash
bash cleanup.sh           # apt autoremove + autoclean, tmp files
bash cleanup.sh --deep    # also: docker system prune, ollama rm unused
```
