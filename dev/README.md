# dev/ — Development Scripts and Tools

Platform scripts for Linux (Ubuntu/ARM64), Android (Magisk/chroot), and Windows.
All scripts use kebab-case naming: `verb-noun.sh` or `category-action.sh`.

---

## Directory Structure

```
dev/
├── README.md                   This file
└── scripts/
    ├── README.md               Full script index and usage table
    ├── linux/                  Ubuntu/ARM64 system scripts (run from chroot)
    │   ├── README.md           Linux scripts guide
    │   ├── sysinfo.sh          Device snapshot — CPU, RAM, GPU, storage, network
    │   ├── perf-tune.sh        SM8150 performance tuning — sysctl.d + udev + systemd
    │   ├── upgrade-stack.sh    Upgrade all dev tools — Go, Rust, Node, Python, k8s
    │   ├── docker-optimize.sh  Docker VFS → overlay2 migration
    │   ├── ollama-config.sh    Ollama CPU affinity + service optimization
    │   ├── k3s-install.sh      Lightweight Kubernetes for ARM64
    │   ├── git-setup.sh        GitHub CLI + SSH key + global git config
    │   ├── ubuntu-post-install.sh  Fresh Ubuntu chroot first-boot setup
    │   └── cleanup.sh          System cleanup — apt, docker, ollama, caches
    └── android/                Scripts requiring Android root (Termux + Magisk su)
        ├── README.md           Android scripts guide
        ├── perf-tune-android.sh    Full SM8150 tuning from Android root
        └── root-enter.sh       Enter Ubuntu chroot as root from Termux
```

---

## Quick Reference

```bash
sysinfo                            # system snapshot
perf-status                        # tuning status (no root needed)
perf-tune --balanced               # apply balanced tuning (needs root)
upgrade --check                    # show all tool versions
upgrade --all                      # upgrade Go + Rust + Python
git-setup                          # GitHub CLI + SSH setup
```

---

## Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Shell scripts | `verb-noun.sh` | `perf-tune.sh`, `git-setup.sh` |
| PowerShell | `Verb-Noun.ps1` | `Remove-BitLocker.ps1` |
| Modes/flags | `--mode` | `--balanced`, `--check`, `--status` |
