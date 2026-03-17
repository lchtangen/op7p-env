# docs/ — Platform Documentation Library

Documentation for all platforms, devices, and projects.
Covers: OnePlus 7 Pro (Android/ARM64), HP EliteBook (Ubuntu), ThinkPad (WSL2), SampleMind AI.

---

## Directory Structure

```
docs/
├── README.md                       This file — documentation index
├── android/                        Android platform (OnePlus 7 Pro GM1913)
│   ├── README.md                   Android platform overview
│   ├── op7p-environment.md         Ubuntu-on-Android definitive guide
│   ├── kernel-custom.md            Custom kernel guide (Kirisakura-NG)
│   ├── magisk-root.md              Magisk root workflow, modules, init.d
│   ├── op7p-setup.html             OP7P setup reference (HTML)
│   └── op7p-setup-v1.html          OP7P setup v1 (HTML, legacy)
├── arm64/                          ARM64 / aarch64 platform
│   ├── README.md                   ARM64 toolchain, compiler flags, cross-compile
│   └── sm8150-hardware.md          Full SM8150 hardware reference — sysfs paths, governors
├── linux/                          Linux desktop/server (Ubuntu)
│   ├── README.md                   Linux platform docs index
│   ├── elitebook-dualboot.md       HP EliteBook 840 G9 Ubuntu 24.04 dual boot
│   ├── ubuntu-upgrade.md           Ubuntu system upgrade procedures
│   └── wslg-setup.md               WSLg (Windows Subsystem for Linux GUI) setup
├── windows/                        Windows 11 + WSL2
│   ├── README.md                   Windows platform docs index
│   ├── thinkpad-wsl2-setup.md      ThinkPad X1 Carbon G8 WSL2 powerhouse setup
│   ├── thinkpad-wsl2-quick.md      ThinkPad WSL2 quick reference
│   └── thinkpad-bios-restore.md    ThinkPad BIOS restoration procedures
└── samplemind/                     SampleMind AI project
    ├── README.md                   Project overview and architecture
    ├── samplemind-dev-setup.md     Full dev environment setup (Python, Node, Go)
    ├── samplemind-ai-engine.md     Hermes AI + OpenVINO + IRMAS neural
    ├── samplemind-frontend.md      Next.js + Tauri desktop + PWA
    ├── samplemind-openvino.md      Intel OpenVINO ARM64 optimization
    └── samplemind-hermes.md        Hermes AI framework architecture
```

---

## Quick Navigation

| I want to... | Go to |
|-------------|-------|
| Set up Ubuntu on OnePlus 7 Pro | `android/op7p-environment.md` |
| Flash a custom kernel | `android/kernel-custom.md` |
| Understand SM8150 hardware / sysfs | `arm64/sm8150-hardware.md` |
| ARM64 compiler flags and toolchain | `arm64/README.md` |
| Dual boot Ubuntu on EliteBook | `linux/elitebook-dualboot.md` |
| Set up WSL2 on ThinkPad | `windows/thinkpad-wsl2-setup.md` |
| Build SampleMind AI | `samplemind/samplemind-dev-setup.md` |
| Understand Magisk root workflow | `android/magisk-root.md` |

---

## Devices Covered

| Device | CPU | OS | Docs |
|--------|-----|----|------|
| OnePlus 7 Pro GM1913 EU | SM8150 / Snapdragon 855 (aarch64) | Android 11 + Ubuntu 24.04 chroot | `android/` `arm64/` |
| HP EliteBook 840 G9 | Intel i5-1235U (x86_64) | Ubuntu 24.04.4 dual boot | `linux/elitebook-dualboot.md` |
| ThinkPad X1 Carbon Gen 8 | Intel i5-10310U (x86_64) | Windows 11 + WSL2 | `windows/thinkpad-wsl2-setup.md` |
