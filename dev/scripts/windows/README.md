# dev/scripts/windows/ — Windows Scripts

PowerShell and batch scripts for Windows administration and SampleMind setup.
Run from **Admin PowerShell** on Windows 11.

---

## Scripts (located in ~/recovery/windows/scripts/)

| Script | Purpose | Run On |
|--------|---------|--------|
| `Remove-BitLocker.ps1` | Permanently disable BitLocker encryption | Windows Admin PowerShell |
| `Shrink-Partition.ps1` | Shrink Windows partition by 120 GB for dual boot | Windows Admin PowerShell |

> **Note:** These scripts are stored in `~/recovery/windows/scripts/` as they are 
> part of the dual-boot preparation / recovery workflow.

---

## Usage

```powershell
# Run as Administrator:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\Remove-BitLocker.ps1
.\Shrink-Partition.ps1
```

---

## Dual Boot Workflow

```
1. Windows: Run Remove-BitLocker.ps1    (disable encryption)
2. Windows: Run Shrink-Partition.ps1    (free 120 GB)
3. Boot Ventoy USB                      (recovery/bootable/)
4. Install Ubuntu                       (docs/linux/elitebook-dualboot.md)
5. Ubuntu: bash ubuntu-post-install.sh  (dev/scripts/linux/)
```

See: `~/docs/linux/elitebook-dualboot.md` for complete EliteBook dual boot guide.
