# recovery/android/ — Android Recovery

TWRP, fastboot, ADB recovery procedures for OnePlus 7 Pro GM1913.

---

## Boot Modes

| Mode | How to Enter | Use |
|------|-------------|-----|
| Normal Android | Power on | Daily use |
| TWRP Recovery | Vol+ + Power (hold) while off | Flash, backup, restore |
| Fastboot / EDL | `adb reboot bootloader` or Vol– + Power | Flash partitions, unlock |
| Safe Mode | Hold Vol– after OnePlus logo | Boot without Magisk modules |

---

## fastboot-recovery.sh

```bash
# From PC with ADB/fastboot connected:
bash ~/recovery/android/fastboot-recovery.sh --flash-stock
bash ~/recovery/android/fastboot-recovery.sh --status
```

---

## ADB Commands

```bash
# Device connection
adb devices                    # list connected devices
adb shell                      # interactive Android shell
adb shell su -c "id"           # root shell via Magisk

# File transfer
adb push ~/file.zip /sdcard/   # push file to device
adb pull /sdcard/file /local/  # pull file from device

# Package management
adb install app.apk
adb uninstall com.package.name

# Reboot modes
adb reboot                     # normal reboot
adb reboot recovery            # boot to TWRP
adb reboot bootloader          # boot to fastboot
adb reboot edl                 # emergency download mode

# Logs
adb logcat                     # Android system log
adb bugreport > bugreport.zip  # full bug report
```

---

## Fastboot Commands (bootloader unlocked)

```bash
fastboot devices               # verify connection
fastboot oem device-info       # show unlock status

# Flash single partition
fastboot flash boot boot.img
fastboot flash recovery twrp.img
fastboot flash system system.img

# OTA sideload via TWRP
adb sideload ota.zip

# Reboot
fastboot reboot
fastboot reboot recovery
```

---

## TWRP Backup & Restore

```
TWRP → Backup → Select: Boot, System, Data
Save to: /sdcard/TWRP/Backups/

Restore: TWRP → Restore → select backup folder → Swipe
```

**Always backup before:**
- Flashing custom kernel
- Installing major Magisk modules
- OTA updates

---

## Stock Boot Image Recovery

```bash
# If boot fails — from fastboot:
fastboot flash boot stock-boot-oos-11.img
fastboot reboot

# Stock images source:
# https://oxygenos.oneplus.net/ (OxygenOS firmware)
# Store at: ~/recovery/android/stock-images/
```

---

## Kernel Flash Recovery

If custom kernel causes bootloop:
1. Power off → Vol+ + Power → TWRP
2. TWRP → Restore → select last backup
3. Or: TWRP → Install → select stock kernel zip
4. Or fastboot: `fastboot flash boot stock-boot.img`

See: `~/docs/android/kernel-custom.md`
