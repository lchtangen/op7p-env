# recovery/windows/ — Windows Recovery

Windows 11 repair, dual-boot preparation, and BIOS procedures.

---

## Scripts

| Script | Purpose | Run |
|--------|---------|-----|
| `scripts/Remove-BitLocker.ps1` | Permanently disable BitLocker | Windows Admin PowerShell |
| `scripts/Shrink-Partition.ps1` | Shrink Windows partition 120 GB | Windows Admin PowerShell |

---

## Usage

```powershell
# Run as Administrator in Windows:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
cd C:\path\to\scripts

# Step 1: Disable BitLocker (required before partition resize)
.\Remove-BitLocker.ps1

# Step 2: Shrink partition for dual boot
.\Shrink-Partition.ps1
```

---

## Windows 11 Recovery Options

```powershell
# System restore
rstrui.exe

# Reset PC (keep files)
Settings → System → Recovery → Reset this PC

# Startup repair
bcdedit /set {default} safeboot minimal   # force safe mode
# Or: hold Shift → Restart → Troubleshoot → Startup Repair

# Fix boot record
bootrec /fixmbr
bootrec /fixboot
bootrec /rebuildbcd
```

---

## Guides

- `~/docs/windows/thinkpad-wsl2-setup.md` — Full ThinkPad WSL2 setup
- `~/docs/windows/thinkpad-bios-restore.md` — BIOS supervisor password
- `~/docs/linux/elitebook-dualboot.md` — EliteBook Ubuntu dual boot
