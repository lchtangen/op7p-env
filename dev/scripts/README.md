# dev/scripts/ — Script Index

| Script | Platform | Root? | Mode Flags | Description |
|--------|----------|-------|------------|-------------|
| `linux/sysinfo.sh` | Linux/ARM64 | No | — | Device snapshot: CPU, RAM, GPU, disk, net |
| `linux/perf-tune.sh` | Linux/ARM64 | Yes | `--max` `--balanced` `--battery` `--status` `--remove` | SM8150 kernel tuning via sysctl.d + udev + systemd |
| `linux/upgrade-stack.sh` | Linux/ARM64 | No | `--check` `--all` `--go` `--rust` `--node` `--python` `--tools` | Upgrade all dev tools |
| `linux/docker-optimize.sh` | Linux | Yes | — | Docker VFS → overlay2 |
| `linux/ollama-config.sh` | Linux | Yes (systemd) | `--status` `--apply` `--bench` | Ollama CPU affinity + service config |
| `linux/k3s-install.sh` | Linux/ARM64 | Yes | `--install` `--uninstall` `--status` `--dashboard` | Lightweight Kubernetes |
| `linux/git-setup.sh` | Linux | No | — | GitHub CLI + ed25519 SSH key + git globals |
| `linux/ubuntu-post-install.sh` | Linux/ARM64 | Yes | — | Fresh chroot first-boot setup |
| `linux/cleanup.sh` | Linux | No/Yes | `--deep` | Free space: apt, docker prune, ollama |
| `android/perf-tune-android.sh` | Android (Termux su) | Yes | `--max` `--balanced` `--battery` `--status` | Full SM8150 sysfs tuning from Android root |
| `android/root-enter.sh` | Android (Termux su) | Yes | — | Enter Ubuntu chroot as root |

---

## Running Scripts

```bash
# No root needed (user-space):
bash ~/dev/scripts/linux/sysinfo.sh
bash ~/dev/scripts/linux/upgrade-stack.sh --check

# Root needed — from Ubuntu chroot (sudo blocked):
# → Run from Termux with Magisk su instead:
su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced"

# Or if chroot has working sudo (other environments):
sudo bash ~/dev/scripts/linux/perf-tune.sh --balanced
```
