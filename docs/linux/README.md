# docs/linux/ — Linux Platform Documentation

Ubuntu and Linux setup guides for x86_64 and ARM64 systems.

---

## Documents

| File | Device | Description |
|------|--------|-------------|
| `elitebook-dualboot.md` | HP EliteBook 840 G9 | Ubuntu 24.04.4 dual boot: BIOS, Secure Boot, Ventoy, MOK |
| `ubuntu-upgrade.md` | Any Ubuntu | System upgrade procedures (20.04→22.04→24.04) |
| `wslg-setup.md` | Windows/WSL2 | WSLg (Linux GUI apps in Windows) setup guide |

---

## HP EliteBook 840 G9 Specs

```
CPU:      Intel Core i5-1235U (12th Gen Alder Lake, x86_64)
GPU:      Intel Iris Xe 80EU
RAM:      16 GB DDR5
Storage:  256 GB NVMe
OS:       Ubuntu 24.04.4 dual boot with Windows 11
```

---

## Ubuntu Post-Install

After installing Ubuntu, run:
```bash
bash ~/dev/scripts/linux/ubuntu-post-install.sh
```

This installs the full development stack: zsh, nvim, tmux, Docker, Go, Rust, Node, Python, Ollama, kubectl, Helm, Terraform.
