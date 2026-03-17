# docs/windows/ — Windows Platform Documentation

Windows 11 + WSL2 setup guides for ThinkPad X1 Carbon Gen 8.

---

## Documents

| File | Description |
|------|-------------|
| `thinkpad-wsl2-setup.md` | Complete WSL2 powerhouse: BIOS, Windows 11, WSL2, Ubuntu, AI stack |
| `thinkpad-wsl2-quick.md` | Quick reference — most-used WSL2 commands |
| `thinkpad-bios-restore.md` | ThinkPad BIOS supervisor password bypass / restoration |

---

## ThinkPad X1 Carbon Gen 8 Specs

```
CPU:      Intel Core i5-10310U (10th Gen Comet Lake, x86_64)
GPU:      Intel UHD 620
RAM:      16 GB LPDDR3
Storage:  256 GB NVMe (Toshiba KXG6AZNV256G)
OS:       Windows 11 + WSL2 Ubuntu
```

---

## Dual Boot Prep (Windows side)

```powershell
# Admin PowerShell:
.\recovery\windows\scripts\Remove-BitLocker.ps1
.\recovery\windows\scripts\Shrink-Partition.ps1
```

See: `~/docs/linux/elitebook-dualboot.md` for full Linux install guide.

## SampleMind on WSL2

WSL2 runs the same SampleMind stack as Ubuntu.
See: `~/docs/samplemind/samplemind-dev-setup.md`
