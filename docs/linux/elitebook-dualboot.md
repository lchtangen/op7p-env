# Ubuntu Dual Boot Installation Guide
## HP EliteBook 840 G9 — Locked BIOS · Secure Boot Enabled · Ventoy USB

**Device:** HP EliteBook 840 G9 | Intel i5-1235U | 16GB RAM | Intel Iris Xe  
**Constraint:** BIOS Supervisor Password locked — Secure Boot cannot be disabled  
**Method:** Ventoy USB + Ubuntu 22.04.3 LTS (Jammy Jellyfish) Secure Boot compatible  
**Date:** March 2026

---

## Critical Understanding Before You Begin

The reason Kali Linux caused Blue Screen of Death errors on this machine is not because Secure Boot is broken — it is because Kali Linux ships with unsigned or minimally signed kernel modules that trigger HP's aggressive firmware-level security validation. Secure Boot treats any unsigned boot component as a potential rootkit and blocks it at the hardware level before the operating system can even load.

Ubuntu 22.04.3 LTS behaves entirely differently. Canonical works directly with Microsoft to ship Ubuntu with a **pre-signed SHIM bootloader** that carries a certificate already trusted by Microsoft's Secure Boot key database. This certificate chain — `Microsoft UEFI CA → Canonical SHIM → Ubuntu GRUB → Ubuntu Kernel` — is valid and recognised by HP's firmware without any BIOS modification. You do not need the BIOS Supervisor Password to install or run Ubuntu when using this method correctly.

This guide executes that process precisely. Every step is sequenced to avoid triggering the violation errors you encountered previously.

---

## Required Materials

You will need the following before starting. Do not proceed without all three items confirmed.

**Ubuntu 22.04.3 LTS Desktop ISO** — Download exclusively from the official Ubuntu releases page: https://releases.ubuntu.com/22.04/ — The filename must be `ubuntu-22.04.3-desktop-amd64.iso` or the most recent point release of 22.04 LTS. Do not use Ubuntu 23.x or 24.04 for this machine at this stage — the 22.04 LTS Secure Boot signing chain has the most stable compatibility record with HP EliteBook enterprise firmware. Version 24.04 LTS is appropriate once you have confirmed stable booting.

**128GB Samsung USB Flash Drive** — This is your Ventoy installation medium. The 128GB capacity is correct: it provides adequate space for the Ubuntu ISO (approximately 5GB), the Ventoy system partition, and optionally a persistence layer. Use a USB 3.0 port on the EliteBook for all operations to avoid timeouts.

**Your Ventoy-prepared USB Drive** — Ventoy must be installed on this drive beforehand. If Ventoy is not yet installed, download the latest release from `ventoy.net` and use the Windows installer (VentoyGUI.exe) to prepare the drive. Copy the Ubuntu ISO to the drive's main partition after Ventoy installation is complete.

---

## Part One — Preparing Ventoy for Secure Boot

This is the step that was either incomplete or incorrectly executed during your previous attempts, and it is the most consequential part of the process.

### Step 1.1 — Verify Ventoy Version

Ventoy must be version 1.0.90 or later for reliable Secure Boot support on HP EliteBook 840 G9 firmware. Open your Windows File Explorer, navigate to the Ventoy USB drive, and locate the `ventoy` folder. Open `version` — it will display the installed Ventoy version number. If it is older than 1.0.90, download the current release from `ventoy.net` and run the update tool, selecting your USB drive and clicking **Update**. Your ISO files on the drive will not be affected.

### Step 1.2 — Enable Ventoy Secure Boot Support

Inside the `ventoy` folder on your USB drive, locate the file named `ENROLL_THIS_KEY_IN_MOKMANAGER.cer`. If this file is not present, your version of Ventoy predates Secure Boot support and must be updated as described in Step 1.1.

Confirm this file is present and note its location. You will navigate to it during the MOK enrollment process in Step 2.3.

### Step 1.3 — Ventoy Configuration for UEFI

In the `ventoy` folder, open or create a file named `ventoy.json`. This configuration file instructs Ventoy to use UEFI-native boot mode, which is required for Secure Boot compatibility. Paste the following content exactly:

```json
{
  "control": [
    { "VTOY_DEFAULT_SEARCH_ROOT": "/Ubuntu" }
  ],
  "theme": {
    "file": ""
  }
}
```

Create a subfolder called `Ubuntu` inside the main USB partition and move your Ubuntu ISO into it. This keeps the Ventoy menu uncluttered and ensures correct path resolution.

---

## Part Two — BIOS Settings Without the Supervisor Password

You cannot access the full BIOS configuration menu because of the Supervisor Password lock. However, HP EliteBook 840 G9 firmware exposes a limited set of boot options to non-privileged users at the **Boot Menu** level, which is separate from the full BIOS Setup. This distinction is critical and is what makes this installation possible.

### Step 2.1 — Access the HP Boot Menu (No Password Required)

Power off the EliteBook completely. Power it on and immediately press **F9** repeatedly — approximately once per second — until the **Boot Menu** appears. This is not the BIOS Setup screen (F10) and does not require the Supervisor Password. It presents a list of detected bootable devices.

If the Boot Menu does not appear, try holding F9 rather than tapping it. If the machine boots directly to Windows, the F9 press window was missed — power off completely and repeat.

### Step 2.2 — Select Your Ventoy USB Drive

In the Boot Menu, your Samsung USB drive will appear listed under **UEFI Boot Sources**. It may be labelled with the drive manufacturer name or as "USB Hard Drive." Select the UEFI entry specifically — not any "Legacy" or "CSM" variant if both appear. Press Enter to boot from it.

### Step 2.3 — MOK Certificate Enrollment (First Boot Only)

On the first Ventoy boot with Secure Boot enabled on a new machine, HP's firmware will intercept the unsigned Ventoy components and redirect to the **MOK Management** screen — a blue-background interface managed by the SHIM bootloader. This is expected and correct behaviour. It is not an error.

Navigate as follows. Select **Enroll key from disk**. The file browser will show your USB drive partitions. Navigate into the `ventoy` folder. Select `ENROLL_THIS_KEY_IN_MOKMANAGER.cer`. On the confirmation screen, select **Continue**. Select **Yes** to confirm the enrollment. Select **Reboot**.

After the reboot, return to the HP Boot Menu (F9) and select your Ventoy USB again. The Ventoy menu will now load directly without interruption. MOK enrollment is permanent for this machine — you will not be asked again.

---

## Part Three — Booting Ubuntu Without Triggering Security Violations

This section addresses specifically why your previous boot attempts resulted in Blue Screen errors and how to avoid repeating them.

### Step 3.1 — Select Ubuntu ISO from Ventoy Menu

From the Ventoy boot menu, select your Ubuntu 22.04.3 LTS ISO. Ventoy will display a secondary menu offering boot mode options. Select **Boot in normal mode**. Do not select "Grub2 Mode" or any persistence option at this stage.

### Step 3.2 — Ubuntu GRUB Menu — Critical Selection

Ubuntu's GRUB bootloader will appear. You will see several options. Use the arrow keys to select **Try or Install Ubuntu** and press Enter immediately. Do not wait for the automatic selection timer, as some HP EliteBook firmware versions have been observed to occasionally select an incorrect option when the timer expires under certain Secure Boot states.

Ubuntu will load its live desktop environment. This may take 60–90 seconds from a USB 3.0 drive on first boot. The desktop will appear with an **Install Ubuntu** shortcut prominently displayed.

---

## Part Four — Partitioning for Dual Boot

Partitioning is the highest-risk phase of this installation. An error here can remove access to Windows. Read each step completely before executing it.

### Step 4.1 — Check Windows Partition State

Before installing Ubuntu, open a terminal in the Ubuntu live environment (right-click desktop → Open Terminal) and run the following command to inspect your current drive layout:

```bash
sudo fdisk -l
```

Identify your NVMe SSD. It will be listed as `/dev/nvme0n1`. Note the existing partitions — you should see at minimum a small EFI partition (around 260MB), a Microsoft Recovery partition, and the main Windows NTFS partition.

Run a second check to confirm Windows left adequate free space for Ubuntu:

```bash
lsblk -f
```

If there is no unallocated space visible on the drive, you will need to shrink the Windows partition first. Skip to **Step 4.2**. If unallocated space of at least 50GB is already present, proceed directly to **Step 4.3**.

### Step 4.2 — Shrink Windows Partition (If Required)

If you did not pre-shrink the Windows partition from within Windows before beginning this installation, open GParted from the Ubuntu live environment:

```bash
sudo apt install gparted -y
sudo gparted
```

Select your NVMe drive from the top-right dropdown. Right-click the Windows NTFS partition and select **Resize/Move**. Shrink it to leave a minimum of 60GB of free space — 80GB is recommended if storage permits. Click the green checkmark to apply changes. This operation will take 5–15 minutes on an NVMe drive. Do not interrupt it.

If GParted reports that the NTFS partition has errors and refuses to resize, boot back into Windows, run `chkdsk C: /f` in an Administrator PowerShell, allow it to complete, reboot Windows once to confirm the filesystem is clean, then return to this step.

### Step 4.3 — Recommended Partition Layout

The following layout is optimised for a dual-boot system with the EliteBook 840 G9's storage configuration. Adjust sizes proportionally if your total drive capacity differs.

| Partition | Mount Point | Size | Filesystem | Notes |
|---|---|---|---|---|
| EFI System | `/boot/efi` | 260MB | FAT32 | **Use existing Windows EFI partition — do not create a new one** |
| Ubuntu root | `/` | 50GB | ext4 | Operating system and all applications |
| Ubuntu home | `/home` | Remaining space | ext4 | All user data and development projects |
| Swap | swap | 8–16GB | swap | Match your RAM size for hibernate support |

The most important instruction in this table is to **use the existing EFI partition** rather than creating a second one. Dual EFI partitions on HP firmware causes unpredictable GRUB detection failures that have no obvious error message and are time-consuming to diagnose and repair.

### Step 4.4 — Ubuntu Installer Partitioning Configuration

Click **Install Ubuntu** from the live desktop. Proceed through language and keyboard selection. On the **Updates and other software** screen, select **Minimal installation** and check **Download updates while installing Ubuntu** if your network connection is active. Uncheck **Install third-party software for graphics and Wi-Fi hardware** — Intel Iris Xe drivers are included in the mainline Ubuntu 22.04 kernel and third-party additions are unnecessary and occasionally cause conflicts.

On the **Installation type** screen, select **Something else**. This gives you manual control over partitioning and is the only safe choice when dual-booting with an existing Windows installation on a machine with Secure Boot enabled.

In the partition table, click the existing EFI partition and select **Use as EFI System Partition** without formatting it. Click your unallocated space and create the partitions specified in Step 4.3 using the **+** button for each. When the partition table reflects your intended layout precisely, click **Install Now**.

When prompted to confirm write operations, click **Continue**. The installer will write the partition table and begin copying files.

---

## Part Five — Completing Installation and Secure Boot Finalisation

### Step 5.1 — Ubuntu Installation

The installation will proceed automatically and takes approximately 15–25 minutes on the EliteBook 840 G9 over a USB 3.0 connection. During this time, complete the user account setup screens — set your full name, username, computer name, and a strong password. The computer name `elitebook-dev` is a reasonable default that clearly identifies the machine in network contexts.

When the installer reports **Installation Complete**, select **Restart Now**. When prompted, remove the USB drive and press Enter.

### Step 5.2 — GRUB Boot Menu Verification

On restart, the GRUB bootloader menu should appear with two entries: **Ubuntu** and **Windows Boot Manager**. If only Ubuntu appears, Windows is still accessible — GRUB may have detected it but placed it in a submenu. Select **Ubuntu** for now and proceed to Step 5.3 to repair the Windows entry if needed after confirming Ubuntu boots correctly.

If the system bypasses GRUB entirely and boots directly to Windows, the HP Boot Menu (F9) is required to select Ubuntu until GRUB priority is established. This is addressed in Step 5.4.

### Step 5.3 — First Ubuntu Boot and System Update

Ubuntu will boot into a fully functional desktop. Open the terminal and run a complete system update before anything else:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
```

This update will include any Secure Boot-related kernel patches released after the ISO was published and is essential for hardware compatibility on the EliteBook 840 G9's 12th Generation Intel platform.

### Step 5.4 — Establish GRUB Boot Priority (Fixes Automatic Windows Boot)

If the system boots directly to Windows without showing GRUB, the HP firmware is prioritising the Windows Boot Manager entry in the EFI boot order over GRUB. Correct this from within Ubuntu:

```bash
# Identify the GRUB EFI entry number
sudo efibootmgr -v

# Look for 'ubuntu' in the output. Note its Boot#### number (e.g., Boot0003)
# Set Ubuntu as the first boot priority
sudo efibootmgr -o 0003,0001,0002
# Replace 0003 with your actual Ubuntu Boot#### number
# Place Windows Boot Manager second in the list
```

Reboot to confirm GRUB now appears automatically. From this point, the five-second GRUB countdown will give you the choice between Ubuntu and Windows on every boot.

---

## Part Six — Post-Installation Configuration for Development

### Step 6.1 — Intel Iris Xe Graphics Driver Verification

Ubuntu 22.04 LTS ships with the `i915` driver that supports Intel Iris Xe. Verify it is active and accelerated:

```bash
sudo apt install -y intel-gpu-tools vainfo
vainfo
# Output should show: VA-API version, iHD driver, and a list of supported profiles
# The presence of H264, HEVC entries confirms hardware acceleration is active

# Check GPU is rendering
glxinfo | grep "OpenGL renderer"
# Should show: Mesa Intel(R) Graphics (ADL GT2) or similar
```

### Step 6.2 — HP EliteBook 840 G9 Hardware Drivers

All core hardware drivers for the EliteBook 840 G9 are included in the Ubuntu 22.04 mainline kernel. However, the following packages improve compatibility and add management features specific to HP hardware:

```bash
sudo apt install -y \
  linux-generic-hwe-22.04 \
  linux-headers-generic-hwe-22.04 \
  firmware-sof-signed \
  alsa-ucm-conf \
  pulseaudio \
  pipewire \
  pipewire-pulse \
  libspa-0.2-bluetooth \
  hplip \
  thermald \
  tlp \
  tlp-rdw \
  powertop
```

The `linux-generic-hwe-22.04` package installs the Hardware Enablement kernel stack, which tracks closer to the mainline kernel releases and provides better support for 12th Generation Intel Core hardware than the standard LTS kernel. `tlp` and `thermald` are essential for thermal and battery management on the EliteBook chassis.

Enable TLP for automatic power management:

```bash
sudo systemctl enable tlp
sudo systemctl start tlp
```

### Step 6.3 — Secure Boot Status Verification

Confirm that Ubuntu is running correctly under Secure Boot — not bypassing it:

```bash
# Check Secure Boot state
mokutil --sb-state
# Expected output: SecureBoot enabled

# Confirm kernel modules are signed
sudo dmesg | grep -i "secure boot"
# Should show: UEFI Secure Boot is enabled

# Verify SHIM is in use
sudo dmesg | grep -i shim
```

All three commands should return positive results. Ubuntu is not bypassing Secure Boot — it is operating correctly within it using Canonical's signed certificate chain. This is the architecturally correct solution for a machine with a locked BIOS.

---

## Part Seven — Development Environment Setup

### Step 7.1 — Core Development Packages

```bash
sudo apt install -y \
  build-essential \
  git \
  curl \
  wget \
  zsh \
  tmux \
  htop \
  tree \
  jq \
  net-tools \
  openssh-client \
  gnupg \
  ca-certificates \
  software-properties-common \
  apt-transport-https \
  libssl-dev \
  libffi-dev \
  ffmpeg \
  libsndfile1-dev \
  portaudio19-dev \
  python3-dev \
  python3-pip \
  python3-venv
```

### Step 7.2 — VS Code

```bash
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg \
  /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
  https://packages.microsoft.com/repos/code stable main" | \
  sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update && sudo apt install code -y
```

### Step 7.3 — Python Environment for SampleMind AI

```bash
# Install pyenv
curl https://pyenv.run | bash

# Add to ~/.zshrc or ~/.bashrc
echo '
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"' >> ~/.zshrc
source ~/.zshrc

# Install Python 3.11.9
pyenv install 3.11.9
pyenv global 3.11.9

# Create SampleMind environment
python -m venv ~/envs/samplemind
source ~/envs/samplemind/bin/activate

pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
pip install librosa soundfile onnxruntime fastapi uvicorn numpy pandas scikit-learn
```

### Step 7.4 — Node.js for SampleMind Web Frontend

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc

nvm install --lts
nvm use --lts

npm install -g pnpm typescript ts-node
```

### Step 7.5 — Docker

```bash
sudo apt install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker
newgrp docker
```

### Step 7.6 — Ollama for Local AI Inference

```bash
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama

# Pull models appropriate for Iris Xe + 16GB RAM
ollama pull llama3.2:3b
ollama pull nomic-embed-text
```

---

## Part Eight — Dual Boot Maintenance and Troubleshooting

### If Windows Is Missing from GRUB After a Windows Update

Windows updates occasionally overwrite EFI boot order entries, restoring Windows Boot Manager to first priority. From Ubuntu, run:

```bash
sudo update-grub
sudo efibootmgr -o XXXX,YYYY
# Where XXXX is Ubuntu's Boot#### and YYYY is Windows
```

### If GRUB Is Missing After a Ubuntu Kernel Update

```bash
sudo grub-install /dev/nvme0n1
sudo update-grub
```

### If Secure Boot Violation Appears Again After a Kernel Update

Ubuntu kernel updates are automatically signed by Canonical's key, which is enrolled in your MOK database. A violation error after a kernel update indicates the new kernel's signature failed to validate. Run:

```bash
sudo mokutil --list-enrolled
# Verify Canonical's certificate is present

sudo update-secureboot-policy --enroll-key
sudo update-grub
```

### GRUB Menu Timeout Configuration

The default GRUB timeout is 10 seconds. To reduce it to 5 seconds and set Ubuntu as the default:

```bash
sudo nano /etc/default/grub
# Change: GRUB_TIMEOUT=5
# Confirm: GRUB_DEFAULT=0

sudo update-grub
```

---

## Summary Reference

| Task | Key Command or Action |
|---|---|
| Access boot menu | F9 immediately at HP logo — no password required |
| Enroll Ventoy MOK | Select from `ventoy/ENROLL_THIS_KEY_IN_MOKMANAGER.cer` |
| Verify Secure Boot active | `mokutil --sb-state` |
| Check GPU driver | `glxinfo \| grep renderer` |
| Update system | `sudo apt update && sudo apt upgrade -y` |
| Repair GRUB | `sudo grub-install /dev/nvme0n1 && sudo update-grub` |
| Fix boot priority | `sudo efibootmgr -o [ubuntu#],[windows#]` |
| Activate SampleMind env | `source ~/envs/samplemind/bin/activate` |
| Start Ollama | `sudo systemctl start ollama` |

---

*HP EliteBook 840 G9 — Ubuntu 22.04.3 LTS Dual Boot Installation Guide*  
*Secure Boot compliant — No BIOS password required — March 2026*
