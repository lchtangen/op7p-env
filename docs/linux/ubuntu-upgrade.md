# Ubuntu 22.04 → 24.04 LTS In-Place Upgrade Guide
## HP EliteBook 840 G9 — Safe Upgrade Without Reinstall

**From:** Ubuntu 22.04.3 LTS (Jammy Jellyfish)  
**To:** Ubuntu 24.04 LTS (Noble Numbat)  
**Device:** HP EliteBook 840 G9 | Intel i5-1235U | Intel Iris Xe  
**Date:** March 2026

---

## When to Upgrade — The Correct Timeline

Do not upgrade immediately after confirming your dual boot works. The correct timeline is:

**Week 1–2:** Confirm Ubuntu 22.04 is fully stable — dual boot, all hardware, WiFi, audio, and your development stack all functioning correctly.

**Week 3+:** When you have a working development environment and have confirmed at least one successful SampleMind session on the machine, then upgrade. Never upgrade a machine mid-project. Always upgrade from a stable, idle state.

The reason for this delay is discipline, not technical limitation. An in-place upgrade that encounters a conflict during an active project costs you far more time than waiting two weeks.

---

## Pre-Upgrade Checklist — Complete Every Item

Before running a single upgrade command, verify all of the following:

```bash
# 1. Check current Ubuntu version
lsb_release -a
# Must show: Ubuntu 22.04.x LTS

# 2. Confirm system is fully updated on 22.04 first
sudo apt update && sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
# Reboot after this completes
sudo reboot

# 3. Check available disk space — upgrade needs minimum 15GB free
df -h /
# Root partition must show at least 15GB available

# 4. Check for held packages that could block upgrade
sudo apt-mark showhold
# Output must be empty — if any packages are held, unhold them:
# sudo apt-mark unhold <package-name>

# 5. Verify no broken packages exist
sudo dpkg --audit
sudo apt --fix-broken install
# Both commands must complete with no errors

# 6. Check Secure Boot is still functioning
mokutil --sb-state
# Must show: SecureBoot enabled

# 7. List your installed PPAs — these may need disabling before upgrade
sudo apt-cache policy | grep http | awk '{print $2}' | sort -u
```

### Backup Your Development Environment First

```bash
# Export Python virtual environments package lists
source ~/envs/samplemind/bin/activate
pip freeze > ~/backup-samplemind-requirements.txt
deactivate

# Backup your entire home directory project folder
tar -czf ~/backup-projects-$(date +%Y%m%d).tar.gz ~/projects/

# Export VS Code extensions list
code --list-extensions > ~/backup-vscode-extensions.txt

# Backup shell configuration
cp ~/.zshrc ~/backup-zshrc
cp ~/.bashrc ~/backup-bashrc
cp ~/.gitconfig ~/backup-gitconfig

# If you have a USB drive or external storage, copy these backups there
echo "Backup complete. Files saved to home directory."
ls ~/backup-*
```

---

## Phase 1 — Disable Third-Party PPAs

Third-party PPAs (Personal Package Archives) are the primary cause of upgrade failures. They must be disabled before upgrading — they will be automatically re-enabled or can be manually re-enabled after the upgrade completes.

```bash
# View all active PPAs
ls /etc/apt/sources.list.d/

# Disable all PPAs safely
sudo sed -i 's/^deb /#deb /g' /etc/apt/sources.list.d/*.list 2>/dev/null
sudo sed -i 's/^deb-src /#deb-src /g' /etc/apt/sources.list.d/*.list 2>/dev/null

# Also disable any entries in sources.list that aren't official Ubuntu
sudo nano /etc/apt/sources.list
# Comment out any non-ubuntu.com lines with # at the start

# Update package cache after disabling PPAs
sudo apt update
```

The PPAs you must specifically check for from your development setup are the Microsoft VS Code repository, the Docker repository, and any Ollama or Python repositories. Note down which ones were active so you can re-enable them after the upgrade.

---

## Phase 2 — Install the Upgrade Tool

```bash
# Install the upgrade manager
sudo apt install -y update-manager-core

# Verify the upgrade configuration targets LTS releases only
sudo nano /etc/update-manager/release-upgrades
# Confirm the file contains:
# Prompt=lts
# If it says 'normal', change it to 'lts' and save
```

---

## Phase 3 — Execute the Upgrade

```bash
# Run the upgrade — this is the main command
sudo do-release-upgrade

# If running over SSH (not applicable for your case but noted for reference),
# use the -f flag:
# sudo do-release-upgrade -f DistUpgradeViewNonInteractive
```

The upgrade process will proceed through several stages. Here is exactly what to expect and how to respond at each prompt:

**Stage 1 — Preparation (5–10 minutes):** The tool fetches package lists and calculates changes. No interaction required.

**Stage 2 — Confirmation prompt:** You will be shown a summary of packages to be installed, updated, and removed. Type **y** and press Enter to confirm.

**Stage 3 — Package download (15–45 minutes depending on WiFi speed):** All packages are downloaded before any changes are made. Do not close the terminal or suspend the machine during this phase.

**Stage 4 — Installation (20–40 minutes):** Packages are installed. You will encounter several interactive prompts:

When asked about configuration files — specifically GRUB configuration (`/etc/default/grub`) — select **Keep the local version currently installed**. This preserves your dual boot timeout and default OS settings.

When asked about any service restart prompts, select **Yes** to allow service restarts.

When asked about removing obsolete packages, select **Yes**.

**Stage 5 — Reboot prompt:** When the upgrade completes, the tool will ask to reboot. Type **y** and press Enter.

---

## Phase 4 — Post-Upgrade Verification

After rebooting into Ubuntu 24.04, complete all verification steps before resuming development work.

### Verify Upgrade Success

```bash
# Confirm Ubuntu version
lsb_release -a
# Must show: Ubuntu 24.04 LTS

# Check kernel version (should be 6.8.x or later)
uname -r

# Verify Secure Boot still active
mokutil --sb-state
# Must show: SecureBoot enabled

# Confirm GRUB dual boot still works
# Reboot and verify Windows entry is present in GRUB menu
```

### Re-Enable Third-Party Repositories

```bash
# Re-enable your PPAs (update the suite name from jammy to noble)
sudo sed -i 's/#deb /deb /g' /etc/apt/sources.list.d/*.list 2>/dev/null

# Update VS Code repository to 24.04 compatible version
# (Microsoft's repo is distribution-agnostic, so it re-enables directly)

# Update Docker repository
sudo apt-get update 2>&1 | grep -i error
# If errors appear for specific PPAs, check if they have a noble release
# PPAs without noble support must stay disabled until the maintainer updates them
```

### Rebuild Development Environment

```bash
# Full system update on 24.04
sudo apt update && sudo apt upgrade -y

# Reinstall any packages that were removed during upgrade
sudo apt install -y \
  build-essential git curl wget zsh tmux \
  ffmpeg libsndfile1-dev portaudio19-dev \
  python3-dev python3-pip python3-venv \
  docker.io docker-compose-plugin \
  intel-gpu-tools vainfo

# Verify Python environments still functional
source ~/envs/samplemind/bin/activate
python --version
pip list | head -20
deactivate

# Restore any missing packages from your backup list
source ~/envs/samplemind/bin/activate
pip install -r ~/backup-samplemind-requirements.txt
deactivate

# Restart Docker
sudo systemctl restart docker
docker ps
```

### Intel Iris Xe on Ubuntu 24.04

Ubuntu 24.04 ships with kernel 6.8, which includes significantly improved Intel Xe graphics support compared to 22.04's kernel 5.15. After upgrading, verify the improvement:

```bash
# Check GPU rendering
glxinfo | grep "OpenGL renderer"
# Should show: Mesa Intel(R) Graphics (ADL GT2)

# Check hardware video acceleration
vainfo
# Should now show additional codec profiles compared to 22.04

# Install updated Intel media driver
sudo apt install -y \
  intel-media-va-driver-non-free \
  libva-drm2 \
  libva-x11-2 \
  libvdpau-va-gl1
```

---

## Rollback Plan — If Upgrade Fails

If the upgrade fails mid-process and the system becomes unbootable, boot from your Ubuntu live USB, open a terminal, and run:

```bash
# Mount your Ubuntu partition
sudo mount /dev/nvme0n1pX /mnt  # Replace X with your Ubuntu root partition number
sudo mount /dev/nvme0n1p1 /mnt/boot/efi

# Chroot into the broken system
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo chroot /mnt

# Attempt to complete or rollback the upgrade
apt --fix-broken install
dpkg --configure -a
do-release-upgrade --partial-upgrade

# If recovery fails, restore GRUB to access Windows
grub-install /dev/nvme0n1
update-grub
exit
sudo umount -R /mnt
```

In the worst case scenario — Ubuntu partition becomes unrecoverable — Windows remains completely untouched and accessible via the HP Boot Menu (F9). Your development work is protected by the project backups created in the pre-upgrade checklist.

---

*Ubuntu 22.04 → 24.04 LTS Upgrade Guide | HP EliteBook 840 G9 | March 2026*
