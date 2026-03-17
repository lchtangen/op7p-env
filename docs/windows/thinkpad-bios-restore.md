# ThinkPad X1 Carbon Gen 8 — BIOS Restore & Windows 11 Installation Guide
**Device:** ThinkPad X1 Carbon Gen 8 | i5-10310U | 16GB RAM | 256GB NVMe (Toshiba KXG6AZNV256G)  
**BIOS Version:** N2WET51W (1.41) | **Install Method:** Ventoy USB  
**Date:** March 2026

---

## ⚠️ Important — What the POST Screen Actually Means

Before proceeding, understand that your POST screen shows **normal and correct hardware specs**. Nothing has been degraded.

| POST Message | What It Actually Means |
|---|---|
| `KXG6AZNV256G TOSHIBA` | Your 256GB NVMe SSD model number — NOT 256MB of graphics |
| `System BIOS shadowed` | BIOS loaded into RAM for faster execution — completely normal |
| `Video BIOS shadowed` | GPU firmware loaded into RAM — completely normal |
| `16384 MB System RAM Passed` | Your 16GB RAM passed hardware test — healthy |
| `BIOS Version N2WET51W (1.41)` | Current firmware version — can be updated via Lenovo Vantage |
| `Intel UHD Graphics` | Integrated into your CPU — cannot be wiped or downgraded by software |

**ThinkShield secure wipe erased your drive contents and reset BIOS settings. It did NOT damage your hardware.**

---

## Phase 1 — BIOS Setup and Factory Reset

### Step 1 — Enter BIOS Setup
- Power on the ThinkPad
- Press **F1** immediately when the Lenovo logo appears
- If you see the POST text screen (like in your photo), press **any key** to exit it, then immediately press **F1** on the next reboot

### Step 2 — Load Factory Defaults
Navigate to: **Restart → Load Setup Defaults → Confirm (Yes)**

This restores all BIOS configurations to Lenovo factory state in one action.

### Step 3 — Configure for Windows 11 + Ventoy Boot

Set the following options precisely:

| BIOS Section | Setting | Value |
|---|---|---|
| Security → Secure Boot | Secure Boot | **Enabled** |
| Startup | UEFI/Legacy Boot | **UEFI Only** |
| Startup | CSM Support | **No** |
| Startup | Boot Order | **USB drive at top** (press F6 to move up) |
| Config → Power | Sleep State | **Windows 10** |
| Security → Virtualization | Intel VT-x | **Enabled** |
| Security → Virtualization | Intel VT-d | **Enabled** |

> 💡 **VT-x and VT-d must be enabled** — these are required later for WSL2 and any virtual machines in your development workflow.

### Step 4 — Save and Exit
Press **F10** → Save Changes and Exit → Confirm

---

## Phase 2 — Ventoy and Secure Boot MOK Enrollment

Ventoy requires a one-time security certificate enrollment before Windows 11 will boot with Secure Boot enabled.

### Step 5 — MOK Certificate Enrollment (First Ventoy Boot)
1. Boot from your Ventoy USB drive
2. Ventoy will display a **MOK Management** screen (blue background)
3. Select **Enroll Key from Disk**
4. Navigate to the `VTOYEFI` folder on your USB
5. Select the file `ENROLL_THIS_KEY_IN_MOKMANAGER.cer`
6. Select **Continue** → **Yes** → **Reboot**

> ⚠️ **If you skip this step**, Secure Boot will block Ventoy from loading on every boot. This enrollment only needs to happen once per machine.

### Step 6 — Select Windows 11 ISO from Ventoy
After the MOK enrollment reboot, the Ventoy menu will appear. Select your **Windows 11 25H2 ISO** and press Enter.

---

## Phase 3 — Windows 11 Installation

### Step 7 — Windows 11 Setup
1. Select **Language, Region, Keyboard** → Next
2. Click **Install Now**
3. On the activation screen, click **I don't have a product key** (Windows 11 will activate automatically via Microsoft account after install)
4. Select **Windows 11 Pro** as the edition
5. Accept the license terms

### Step 8 — Drive Partitioning (Critical Step)
1. Select **Custom: Install Windows only (advanced)**
2. You will see your NVMe SSD listed with any existing partitions
3. **Delete every partition** on the NVMe drive one by one until only **Unallocated Space** remains
4. Select the unallocated space and click **Next**
5. Windows will create the required partitions automatically (EFI, MSR, Primary)

> ⚠️ **Do not manually create partitions** — let Windows 11 handle partition creation on unallocated space. This ensures correct GPT/UEFI partition structure.

### Step 9 — Complete Setup
Allow the installation to complete. The system will reboot several times automatically. Complete the Windows Out-of-Box Experience (OOBE) setup — connect to WiFi, sign in with or create a Microsoft account.

---

## Phase 4 — Post-Installation Driver and Firmware Updates

### Step 10 — Install Lenovo Vantage
1. Open the **Microsoft Store** immediately after first login
2. Search for **Lenovo Vantage** and install it
3. Open Lenovo Vantage → **System Update**
4. Install **all available updates**, prioritising in this order:
   - BIOS/Firmware updates (this will update from 1.41 to the latest version)
   - Intel graphics driver (restores full UHD 620 capability)
   - Thunderbolt firmware
   - Touchscreen driver (restores touch functionality)
   - All remaining device drivers

> 💡 **The BIOS update is the most important step here.** Lenovo's current firmware for the X1 Carbon Gen 8 includes power management improvements, security patches, and full hardware feature restoration. Run it before anything else.

### Step 11 — Verify Hardware Restoration
After all updates and a final reboot, verify the following in **Device Manager** (right-click Start → Device Manager):

- **Display adapters** → Intel UHD Graphics 620 (no error flags)
- **Human Interface Devices** → HID-compliant touch screen present
- **Thunderbolt** → Intel Thunderbolt controller present
- **Network adapters** → Intel WiFi 6 AX201 present

All hardware should be fully functional at this point.

---

## Phase 5 — Development Environment Setup (Post-Windows Install)

### Step 12 — WSL2 Ubuntu 24.04 LTS
Open **PowerShell as Administrator** and run:

```powershell
wsl --install -d Ubuntu-24.04
```

Reboot when prompted. Ubuntu 24.04 LTS will be installed with WSL2 as the default backend.

### Step 13 — VS Code with WSL Integration
1. Download and install [VS Code](https://code.visualstudio.com)
2. Open VS Code → Extensions (Ctrl+Shift+X)
3. Install **Remote - WSL** (by Microsoft)
4. Open a new window → press **F1** → type `WSL: New Window`
5. All development now runs natively inside Ubuntu via WSL2

### Step 14 — Python Environment (SampleMind AI)
Inside WSL2 Ubuntu terminal:

```bash
# Install pyenv dependencies
sudo apt update && sudo apt install -y \
  build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev \
  curl libncursesw5-dev xz-utils tk-dev \
  libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Install pyenv
curl https://pyenv.run | bash

# Add to shell (paste into ~/.bashrc)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Reload shell and install Python 3.11
source ~/.bashrc
pyenv install 3.11.9
pyenv global 3.11.9

# Create SampleMind virtual environment
python -m venv ~/envs/samplemind
source ~/envs/samplemind/bin/activate

# Install core SampleMind dependencies
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
pip install librosa soundfile onnxruntime numpy pandas
```

### Step 15 — Node.js for Web Development (SampleMind Frontend)
Inside WSL2 Ubuntu:

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc

# Install Node.js LTS
nvm install --lts
nvm use --lts

# Install Next.js project scaffolding
npx create-next-app@latest samplemind-web --typescript --tailwind --eslint
```

---

## Quick Reference — BIOS Key Commands

| Action | Key |
|---|---|
| Enter BIOS Setup | F1 at Lenovo logo |
| Boot Menu (one-time) | F12 at Lenovo logo |
| Save and Exit BIOS | F10 |
| Load Setup Defaults | F9 |
| Move boot order item up | F6 |

---

## Hardware Specifications Reference (Confirmed Normal)

| Component | Specification |
|---|---|
| CPU | Intel Core i5-10310U @ 1.70GHz (4C/8T, 10th Gen) |
| RAM | 16GB LPDDR3 (16384 MB) |
| Storage | 256GB Toshiba NVMe SSD (KXG6AZNV256G) |
| Graphics | Intel UHD Graphics 620 (integrated) |
| L2 Cache | 1024 KB |
| BIOS | Phoenix SecureCore N2WET51W |
| Display | 14" FHD IPS with touch (after driver restore) |

---

*Guide prepared for ThinkPad X1 Carbon Gen 8 restoration — March 2026*
