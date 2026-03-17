# docs/android/ — Android Platform Documentation

OnePlus 7 Pro GM1913 EU — Qualcomm Snapdragon 855 (SM8150), aarch64.
Android 11 (OxygenOS) + Ubuntu 24.04.4 LTS chroot + Magisk root.

---

## Documents

| File | Description |
|------|-------------|
| `op7p-environment.md` | Definitive Ubuntu-on-Android guide: chroot, root, tools, limitations |
| `kernel-custom.md` | Custom kernel upgrade guide: Kirisakura-NG, Sultan, KernelSU |
| `magisk-root.md` | Magisk root workflow: modules, init.d, root from chroot, SafetyNet |
| `op7p-setup.html` | Original OP7P setup reference (HTML, v2) |
| `op7p-setup-v1.html` | Original OP7P setup reference (HTML, v1 legacy) |

---

## Device Quick Reference

```
SoC:      Qualcomm Snapdragon 855 (SM8150), 7 nm
CPU:      Kryo 485 — 1× Prime 2.84 GHz, 3× Gold 2.42 GHz, 4× Silver 1.79 GHz
GPU:      Adreno 640v2, 585 MHz max, 5 power levels (0=max, 4=min)
RAM:      12 GB LPDDR4X
Storage:  256 GB UFS 3.0
Kernel:   4.14.180-perf+ (Qualcomm CAF Android fork, clang 10.0.7 NDK)
Android:  11 / OxygenOS
Root:     Magisk (unlocked bootloader)
Recovery: TWRP installed
```

---

## Architecture: Ubuntu on Android

```
Hardware (SM8150)
└── Android Kernel 4.14.180-perf+ (Qualcomm CAF)
    └── Android 11 (OxygenOS)
        └── Magisk (root, systemless)
            └── Termux (Android terminal emulator)
                └── Ubuntu 24.04.4 chroot (ltangen user)
                    ├── zsh + Oh My Zsh
                    ├── Docker, Ollama, kubectl, Helm
                    ├── Go 1.26.1, Rust 1.94.0, Node 24.14.0
                    └── Claude Code, Neovim, tmux
```

---

## Key Limitation: No Root in Chroot

The Ubuntu chroot has `CapEff: 0x0` — zero kernel capabilities.
All sysfs/proc writes (performance tuning) must be done from **Termux with Magisk `su`**.

```bash
# From Termux:
su -c "bash /storage/emulated/0/dev/scripts/android/perf-tune-android.sh --balanced"
```

See: `dev/scripts/android/README.md` for full Android root script documentation.
