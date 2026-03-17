#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Permanently removes BitLocker encryption from drive C:
    Must run BEFORE shrink-partition.ps1 and BEFORE Ubuntu install
    Run as: Right-click PowerShell → "Run as Administrator"
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== SampleMind — BitLocker Removal Script ===" -ForegroundColor Cyan
Write-Host "Device: HP EliteBook 840 G9 / ThinkPad X1 Carbon G8" -ForegroundColor Cyan
Write-Host ""

# ─── Step 1: Check BitLocker Status ─────────────────────────────────────────
Write-Host "[1/5] Checking BitLocker status on C:..." -ForegroundColor Yellow
$blStatus = manage-bde -status C:
Write-Host $blStatus

$protectionStatus = (Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue)
if ($null -eq $protectionStatus) {
    Write-Host "BitLocker not found or already disabled. Continuing..." -ForegroundColor Green
} elseif ($protectionStatus.ProtectionStatus -eq "Off") {
    Write-Host "BitLocker protection is already OFF." -ForegroundColor Green
    # May still be in decryption — check encryption percentage below
} else {
    Write-Host "BitLocker is ACTIVE. Proceeding with removal..." -ForegroundColor Red
}

# ─── Step 2: Disable BitLocker ───────────────────────────────────────────────
Write-Host ""
Write-Host "[2/5] Disabling BitLocker on C:..." -ForegroundColor Yellow
try {
    Disable-BitLocker -MountPoint "C:" -ErrorAction Stop
    Write-Host "BitLocker disable command sent successfully." -ForegroundColor Green
} catch {
    Write-Host "Disable-BitLocker failed, trying manage-bde fallback..." -ForegroundColor Yellow
    manage-bde -off C:
}

# ─── Step 3: Wait for Full Decryption ────────────────────────────────────────
Write-Host ""
Write-Host "[3/5] Waiting for full decryption (this takes 5–30 minutes)..." -ForegroundColor Yellow
Write-Host "Progress updates every 30 seconds. Do NOT restart or shut down." -ForegroundColor Cyan

$maxWait  = 120    # max 60 minutes (120 * 30s)
$attempts = 0
do {
    Start-Sleep -Seconds 30
    $attempts++
    $vol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

    if ($null -eq $vol) {
        Write-Host "BitLocker volume info unavailable — likely fully decrypted." -ForegroundColor Green
        break
    }

    $pct = $vol.EncryptionPercentage
    $status = $vol.VolumeStatus
    Write-Host "  [$($attempts * 30)s] Status: $status | Encrypted: $pct%" -ForegroundColor White

    if ($pct -eq 0 -or $status -eq "FullyDecrypted") {
        Write-Host "Drive fully decrypted!" -ForegroundColor Green
        break
    }
    if ($attempts -ge $maxWait) {
        Write-Host "Timeout reached. Check status manually: manage-bde -status C:" -ForegroundColor Red
        break
    }
} while ($true)

# ─── Step 4: Block BitLocker Re-Encryption ────────────────────────────────────
Write-Host ""
Write-Host "[4/5] Blocking BitLocker auto-enable via registry..." -ForegroundColor Yellow

$fveKey = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker"
if (-not (Test-Path $fveKey)) {
    New-Item -Path $fveKey -Force | Out-Null
}
Set-ItemProperty -Path $fveKey -Name "PreventDeviceEncryption" -Value 1 -Type DWord
Write-Host "Registry: PreventDeviceEncryption = 1" -ForegroundColor Green

# Disable BDESVC service (BitLocker Drive Encryption Service)
try {
    Stop-Service -Name "BDESVC" -Force -ErrorAction SilentlyContinue
    Set-Service  -Name "BDESVC" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "BDESVC service disabled." -ForegroundColor Green
} catch {
    Write-Host "BDESVC service not found (OK on some Windows editions)." -ForegroundColor Yellow
}

# Disable Fast Startup (causes issues with dual boot NTFS access)
$powerKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
Set-ItemProperty -Path $powerKey -Name "HiberbootEnabled" -Value 0 -Type DWord
Write-Host "Fast Startup disabled (HiberbootEnabled = 0)" -ForegroundColor Green

# ─── Step 5: Final Verification ──────────────────────────────────────────────
Write-Host ""
Write-Host "[5/5] Final verification..." -ForegroundColor Yellow
$finalVol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
if ($null -ne $finalVol) {
    Write-Host "BitLocker status: $($finalVol.VolumeStatus)" -ForegroundColor White
    Write-Host "Encryption:       $($finalVol.EncryptionPercentage)%" -ForegroundColor White
    Write-Host "Protection:       $($finalVol.ProtectionStatus)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Green
Write-Host "Next step: Run shrink-partition.ps1 to free 120GB for Ubuntu" -ForegroundColor Cyan
Write-Host ""
