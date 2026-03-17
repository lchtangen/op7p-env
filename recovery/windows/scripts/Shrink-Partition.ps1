#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Shrinks Windows partition by 120GB (122,880MB) to make room for Ubuntu.
    Run AFTER remove-bitlocker.ps1 — BitLocker must be fully off first.
    Run as: Right-click PowerShell → "Run as Administrator"
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SHRINK_MB = 122880    # 120 GiB — Ubuntu: 60GB root + 50GB home + 10GB swap

Write-Host "=== SampleMind — Windows Partition Shrink ===" -ForegroundColor Cyan
Write-Host "Shrinking C: by ${SHRINK_MB}MB (120GB) for Ubuntu 24.04.4" -ForegroundColor Cyan
Write-Host ""

# ─── Step 1: Check BitLocker is OFF ──────────────────────────────────────────
Write-Host "[1/5] Verifying BitLocker is disabled..." -ForegroundColor Yellow
$vol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
if ($null -ne $vol -and $vol.ProtectionStatus -ne "Off") {
    Write-Host "ERROR: BitLocker is still active ($($vol.VolumeStatus))" -ForegroundColor Red
    Write-Host "Run remove-bitlocker.ps1 first and wait for full decryption." -ForegroundColor Red
    exit 1
}
Write-Host "BitLocker: OFF — safe to resize." -ForegroundColor Green

# ─── Step 2: Check Available Shrink Space ────────────────────────────────────
Write-Host ""
Write-Host "[2/5] Checking available shrink space on C:..." -ForegroundColor Yellow

$cDrive = Get-Partition -DriveLetter C
$supported = Get-PartitionSupportedSize -DriveLetter C
$maxShrinkMB = [math]::Floor(($supported.SizeMax - $supported.SizeMin) / 1MB)

Write-Host "Drive C: Partition number: $($cDrive.PartitionNumber)" -ForegroundColor White
Write-Host "Current size: $([math]::Round($cDrive.Size/1GB,1))GB" -ForegroundColor White
Write-Host "Max shrinkable: ${maxShrinkMB}MB ($([math]::Round($maxShrinkMB/1024,1))GB)" -ForegroundColor White

if ($maxShrinkMB -lt $SHRINK_MB) {
    Write-Host "WARNING: Only ${maxShrinkMB}MB available to shrink (need ${SHRINK_MB}MB)" -ForegroundColor Red
    Write-Host "Free up space on C: or run Disk Cleanup before retrying." -ForegroundColor Red

    # Try diskpart as fallback with maximum available space
    $fallbackMB = $maxShrinkMB - 2048    # Leave 2GB buffer
    Write-Host "Attempting diskpart fallback with ${fallbackMB}MB..." -ForegroundColor Yellow

    $diskpartScript = @"
select volume C
shrink desired=$fallbackMB minimum=$fallbackMB
exit
"@
    $tempFile = "$env:TEMP\shrink_diskpart.txt"
    $diskpartScript | Out-File -FilePath $tempFile -Encoding ASCII
    diskpart /s $tempFile
    Remove-Item $tempFile
    goto Step3
}

# ─── Step 3: Shrink Partition ────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/5] Shrinking C: by ${SHRINK_MB}MB..." -ForegroundColor Yellow

try {
    # Primary method: Resize-Partition
    $newSizeBytes = $supported.SizeMin + (($supported.SizeMax - $supported.SizeMin) - ($SHRINK_MB * 1MB))
    Resize-Partition -DriveLetter C -Size $newSizeBytes
    Write-Host "Partition resized successfully via Resize-Partition." -ForegroundColor Green
} catch {
    Write-Host "Resize-Partition failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Trying diskpart fallback..." -ForegroundColor Yellow

    $diskpartScript = @"
select volume C
shrink desired=$SHRINK_MB minimum=$SHRINK_MB
exit
"@
    $tempFile = "$env:TEMP\shrink_diskpart.txt"
    $diskpartScript | Out-File -FilePath $tempFile -Encoding ASCII
    $result = diskpart /s $tempFile
    Remove-Item $tempFile
    Write-Host $result
}

# ─── Step 4: Verify Unallocated Space ────────────────────────────────────────
Write-Host ""
Write-Host "[4/5] Verifying unallocated space..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

$disk = Get-Disk | Where-Object { $_.IsBoot -eq $true }
$allPartitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue
$diskSizeGB     = [math]::Round($disk.Size / 1GB, 1)
$partitionSumGB = [math]::Round(($allPartitions | Measure-Object -Property Size -Sum).Sum / 1GB, 1)
$unallocatedGB  = [math]::Round($diskSizeGB - $partitionSumGB, 1)

Write-Host "Disk total:       ${diskSizeGB}GB" -ForegroundColor White
Write-Host "Partitions total: ${partitionSumGB}GB" -ForegroundColor White
Write-Host "Unallocated:      ${unallocatedGB}GB" -ForegroundColor $(if ($unallocatedGB -gt 100) { "Green" } else { "Red" })

if ($unallocatedGB -lt 100) {
    Write-Host "WARNING: Expected ~120GB unallocated but got ${unallocatedGB}GB" -ForegroundColor Red
    Write-Host "Open Disk Management (Win+X → Disk Management) to verify." -ForegroundColor Yellow
}

# ─── Step 5: Open Disk Management for Visual Verification ────────────────────
Write-Host ""
Write-Host "[5/5] Opening Disk Management for visual verification..." -ForegroundColor Yellow
Start-Process "diskmgmt.msc"

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Green
Write-Host "Unallocated space: ~${unallocatedGB}GB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Confirm unallocated space in Disk Management (black bar)" -ForegroundColor White
Write-Host "  2. Shut down Windows completely (not restart)" -ForegroundColor White
Write-Host "  3. Boot Ventoy USB via F9 and install Ubuntu 24.04.4" -ForegroundColor White
Write-Host "  4. Follow ELITEBOOK-DUALBOOT.md — Part 3 for partition layout" -ForegroundColor White
Write-Host ""
