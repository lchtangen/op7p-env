# ThinkPad X1 Carbon G8 — WSL2 Powerhouse Setup
### Windows 11 + WSL2 Ubuntu 24.04 + Tokyo Night Cyberpunk Environment
---
**Device:** ThinkPad X1 Carbon Gen 8 | i5-10310U | Intel UHD 620 | 16GB RAM
**Storage:** 256GB NVMe — Toshiba KXG6AZNV256G (this is the SSD model number — NOT 256MB GPU)
**Setup:** WSL2 Ubuntu 24.04 LTS for all SampleMind development

---

## Part 1 — ThinkPad BIOS Setup

### What the POST Screen Shows
At startup you may see `KXG6AZNV256G 256GB` — this is the **Toshiba NVMe SSD model number**, not a GPU. The UHD 620 GPU uses shared system RAM and does not show its own storage.

### BIOS Access Keys
| Key | Function |
|-----|----------|
| F1 | BIOS Setup (ThinkPad BIOS — no supervisor password typically) |
| F10 | Boot device selection |
| F9 | Restore BIOS defaults inside BIOS setup |
| F6 | ThinkVantage / Diagnostics |
| Enter → F1 | If shown "To interrupt normal startup press Enter" |

### Step 1.1 — Access BIOS and Load Defaults
1. Power off → press power button → immediately press F1 (or Enter then F1)
2. In BIOS, navigate to **Security** tab:
   - Secure Boot: **On**
   - Boot → Boot Mode: **UEFI Only**
   - Boot → CSM Support: **No**
   - Security → Virtualization: **Enable Intel VT-x**
   - Security → Virtualization → Intel VT-d: **Enable**
3. Navigate to **Restart** tab → **Load Setup Defaults** (F9)
4. Re-apply the settings above (defaults may reset them)
5. **F10** → Save and Exit

### Step 1.2 — Ventoy USB + Windows 11 Install
1. Boot Ventoy USB: press F10 at startup → select USB (UEFI entry)
2. MOK enrollment if prompted — same process as EliteBook guide
3. Select Windows 11 ISO from Ventoy
4. In Windows Setup: **Custom: Install Windows only (advanced)**
5. **Delete ALL existing partitions** until only "Unallocated Space" remains
6. Click New → let Windows create its own EFI + MSR + primary partitions automatically
7. Click Next → Installation proceeds (~20 minutes)

### Step 1.3 — Post-Install: Lenovo Vantage
After Windows 11 first boot:
1. Open Microsoft Store → search "Lenovo Vantage" → Install
2. Vantage auto-detects ThinkPad and installs:
   - Intel UHD 620 driver
   - Intel ME firmware
   - Thunderbolt 3 driver
   - Audio (Realtek + Dolby)
   - Fingerprint (if model has it)
3. Run Windows Update until no more updates pending
4. Restart

---

## Part 2 — WSL2 Powerhouse Setup

### Step 2.1 — Windows Optimizations (Do These First)
```powershell
# Run as Administrator

# 1. Set High Performance power plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# 2. Enable Long Paths (required for Node.js/npm)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
  -Name "LongPathsEnabled" -Value 1

# 3. Windows Defender exclusions for WSL2 (huge performance gain)
Add-MpPreference -ExclusionPath "$env:USERPROFILE\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu*"
Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\AppData\Local\Temp"
Add-MpPreference -ExclusionProcess "wsl.exe"
Add-MpPreference -ExclusionProcess "wslhost.exe"
Add-MpPreference -ExclusionProcess "vmmemWSL"
```

### Step 2.2 — Install WSL2 + Ubuntu 24.04
```powershell
# PowerShell (Admin)
wsl --install
wsl --install -d Ubuntu-24.04
# Restart when prompted
# After restart:
wsl --set-default Ubuntu-24.04
wsl --set-default-version 2
```

### Step 2.3 — WSL2 Memory Configuration
Create `C:\Users\$USERNAME\.wslconfig`:
```ini
[wsl2]
memory=10GB
processors=4
swap=8GB
swapFile=C:\Temp\wsl-swap.vhdx
localhostForwarding=true
nestedVirtualization=true
guiApplications=true
autoMemoryReclaim=gradual
kernelCommandLine=sysctl.vm.swappiness=10

[experimental]
sparseVhd=true
autoMemoryReclaim=gradual
```

### Step 2.4 — WSL2 Internal Configuration
Inside WSL2, create `/etc/wsl.conf`:
```bash
sudo nano /etc/wsl.conf
```
```ini
[automount]
enabled=true
options="metadata,umask=22,fmask=11"
mountFsTab=true

[network]
hostname=thinkpad-dev
generateHosts=true
generateResolvConf=true

[interop]
enabled=true
appendWindowsPath=false

[boot]
systemd=true
```
Then restart: from PowerShell run `wsl --shutdown`, reopen WSL2.

### Step 2.5 — System Tuning Inside WSL2
```bash
# sysctl tuning
sudo tee /etc/sysctl.d/99-samplemind.conf <<EOF
vm.swappiness=10
vm.dirty_ratio=60
vm.dirty_background_ratio=2
net.core.rmem_max=134217728
net.core.wmem_max=134217728
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512
fs.file-max=2097152
EOF
sudo sysctl --system

# zram compressed swap (better than disk swap)
sudo apt install -y zram-tools
sudo tee /etc/default/zramswap <<EOF
ALGO=zstd
PERCENT=25
EOF
sudo systemctl enable zramswap
sudo systemctl start zramswap

# SSH hardening
sudo apt install -y openssh-server
sudo tee -a /etc/ssh/sshd_config <<EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
EOF

# UFW firewall
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 3000/tcp  # Next.js dev
sudo ufw allow 8000/tcp  # FastAPI
sudo ufw allow 8080/tcp  # OpenWebUI
sudo ufw allow 8888/tcp  # Jupyter
sudo ufw --force enable
```

### Step 2.6 — VS Code Integration
Install VS Code on Windows from code.visualstudio.com. Then inside WSL2:
```bash
code .   # Opens VS Code on Windows with WSL2 remote extension auto-installed
```
VS Code settings for SampleMind (`%APPDATA%\Code\User\settings.json` on Windows):
```json
{
  "editor.fontFamily": "'JetBrains Mono', 'Cascadia Code', Consolas, monospace",
  "editor.fontSize": 14,
  "editor.lineHeight": 1.6,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.tabSize": 2,
  "workbench.colorTheme": "Tokyo Night",
  "terminal.integrated.fontFamily": "'JetBrains Mono Nerd Font'",
  "python.defaultInterpreterPath": "~/envs/samplemind/bin/python",
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.venv/**": true,
    "**/__pycache__/**": true
  }
}
```

### Step 2.7 — WSL2 Backup
```powershell
# From PowerShell — backup WSL2 to file
wsl --export Ubuntu-24.04 "C:\Backups\ubuntu-24-04-backup.tar"
# Restore:
wsl --import Ubuntu-24.04-restore "C:\WSL\Ubuntu24" "C:\Backups\ubuntu-24-04-backup.tar"
```

---

## Part 3 — WSLg GUI Applications

### Step 3.1 — Verify WSLg is Working
WSLg (Windows Subsystem for Linux GUI) is built into WSL2 v2.0+. Verify:
```bash
# Inside WSL2
echo $DISPLAY        # Should output something like :0
echo $WAYLAND_DISPLAY # Should output wayland-0

# Test with a GUI app
sudo apt install -y x11-apps
xclock   # A clock window should appear on Windows desktop
```
If nothing appears: update WSL2 from PowerShell (`wsl --update`), restart (`wsl --shutdown`).

### Step 3.2 — Install GUI Applications via WSL2
```bash
sudo apt install -y \
  audacity \
  gimp \
  dbeaver-ce \
  gedit

# Thorium browser (fast Chromium fork)
wget -q https://github.com/Alex313031/thorium/releases/latest/download/thorium-browser_amd64.deb
sudo dpkg -i thorium-browser_amd64.deb
sudo apt install -f -y

# Figma Linux via Flatpak
sudo apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub io.github.Figma_Linux.figma_linux
```

---

## Part 4 — Tokyo Night Cyberpunk Environment

### Step 4.1 — JetBrains Mono Nerd Font
```bash
mkdir -p ~/.local/share/fonts/JetBrainsMono
cd ~/.local/share/fonts/JetBrainsMono
wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
unzip JetBrainsMono.zip -d .
fc-cache -fv
```

### Step 4.2 — Tokyo Night GTK Theme
```bash
git clone https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme.git /tmp/tokyo-night-gtk
mkdir -p ~/.themes
cp -r /tmp/tokyo-night-gtk/themes/Tokyonight-Dark-BL ~/.themes/

# GTK 3 config
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Tokyonight-Dark-BL
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrains Mono 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
EOF

# GTK 4 config
mkdir -p ~/.config/gtk-4.0
cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

# Apply via dconf
gsettings set org.gnome.desktop.interface gtk-theme "Tokyonight-Dark-BL"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface font-name "JetBrains Mono 11"
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 12"

# Icons
sudo apt install -y papirus-icon-theme
```

### Step 4.3 — Alacritty Terminal
```bash
sudo apt install -y alacritty

mkdir -p ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.toml <<EOF
[window]
opacity = 0.92
padding = { x = 16, y = 12 }
decorations = "full"

[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
size = 13.0

[cursor]
style = { shape = "Beam", blinking = "On" }
blink_interval = 500
unfocused_hollow = true

[colors.primary]
background = "#1a1b26"
foreground = "#c0caf5"

[colors.cursor]
text = "#1a1b26"
cursor = "#00f5ff"

[colors.normal]
black   = "#15161e"
red     = "#f7768e"
green   = "#9ece6a"
yellow  = "#e0af68"
blue    = "#7aa2f7"
magenta = "#bb9af7"
cyan    = "#7dcfff"
white   = "#a9b1d6"

[colors.bright]
black   = "#414868"
red     = "#f7768e"
green   = "#9ece6a"
yellow  = "#e0af68"
blue    = "#7aa2f7"
magenta = "#bb9af7"
cyan    = "#7dcfff"
white   = "#c0caf5"
EOF
```

### Step 4.4 — Neovim + NvChad
```bash
# Neovim AppImage (latest stable)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
tar xzf nvim-linux64.tar.gz
sudo mv nvim-linux64 /opt/nvim
sudo ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim

# NvChad starter config
git clone https://github.com/NvChad/starter ~/.config/nvim
nvim  # Run once — NvChad installs itself via lazy.nvim
```

### Step 4.5 — Rofi Launcher
```bash
sudo apt install -y rofi fonts-font-awesome

mkdir -p ~/.config/rofi
cat > ~/.config/rofi/config.rasi <<EOF
configuration {
  modi: "drun,run,window";
  show-icons: true;
  icon-theme: "Papirus-Dark";
  display-drun: " Apps";
  display-run: " Run";
  display-window: " Windows";
  drun-display-format: "{name}";
  font: "JetBrains Mono Nerd Font 12";
}

@theme "tokyo-night"

* {
  bg: #1a1b26;
  bg-alt: #16161e;
  fg: #c0caf5;
  fg-alt: #7aa2f7;
  border: #7aa2f7;
  selected: #7aa2f7;
  selected-fg: #1a1b26;
}
EOF
# Invoke with: rofi -show drun
# Bind to a keyboard shortcut in your DE settings
```

### Step 4.6 — Zsh + Oh My Zsh + Powerlevel10k
```bash
sudo apt install -y zsh
chsh -s $(which zsh)

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Update ~/.zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting z docker)/' ~/.zshrc

# Restart shell
exec zsh
# p10k configure  ← run for interactive setup
```

### Step 4.7 — devenv Launcher Script
```bash
cat > ~/devenv <<'EOF'
#!/bin/bash
# SampleMind dev launcher — opens all tools in tmux
SESSION="samplemind"
PROJ="$HOME/projects/samplemind"

tmux new-session -d -s $SESSION -n "backend" -c $PROJ
tmux send-keys -t $SESSION:backend "source ~/envs/samplemind/bin/activate && make backend" Enter

tmux new-window -t $SESSION -n "frontend" -c "$PROJ/frontend"
tmux send-keys -t $SESSION:frontend "npm run dev" Enter

tmux new-window -t $SESSION -n "ollama" -c $PROJ
tmux send-keys -t $SESSION:ollama "ollama serve" Enter

tmux new-window -t $SESSION -n "monitor" -c $PROJ
tmux send-keys -t $SESSION:monitor "btop" Enter

tmux new-window -t $SESSION -n "shell" -c $PROJ
tmux send-keys -t $SESSION:shell "source ~/envs/samplemind/bin/activate" Enter

# Open browser (WSLg or Windows)
sleep 3
if command -v thorium-browser &>/dev/null; then
  thorium-browser http://localhost:3000 &>/dev/null &
else
  cmd.exe /c start http://localhost:3000 2>/dev/null
fi

tmux attach -t $SESSION
EOF
chmod +x ~/devenv
echo 'alias dev="~/devenv"' >> ~/.zshrc
```

### Step 4.8 — Modern CLI Tools
```bash
sudo apt install -y bat ripgrep fd-find fzf tmux htop ncdu

# exa (modern ls)
sudo apt install -y cargo
cargo install exa
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc

# btop (modern htop)
sudo snap install btop

# Aliases
cat >> ~/.zshrc <<'EOF'
alias ls="exa --icons"
alias ll="exa -la --icons --git"
alias lt="exa --tree --icons --level=2"
alias cat="bat --style=numbers"
alias find="fd"
alias grep="rg"
alias top="btop"
alias python="python3"
alias pip="pip3"
alias activate="source ~/envs/samplemind/bin/activate"
alias dev="~/devenv"
EOF
```

---

## Part 5 — SampleMind on ThinkPad (OpenVINO CPU Mode)

The SampleMind stack runs identically on ThinkPad WSL2. The key difference is OpenVINO acceleration:

```python
# In samplemind/ai/openvino_wrapper.py — this auto-detects correctly on ThinkPad
import openvino as ov

def get_device():
    core = ov.Core()
    available = core.available_devices
    # ThinkPad UHD 620 may not support OpenVINO GPU compute
    # CPU fallback is automatic and still fast for inference
    return "GPU" if "GPU" in available else "CPU"
```

The `SAMPLEMIND-DEV-SETUP.md` installation steps work identically in WSL2 — pyenv, Python 3.11.9, all pip packages, Docker, Ollama, Node.js are all the same.

RAM budget on ThinkPad (WSL2 gets 10GB):
| Service | RAM |
|---------|-----|
| WSL2 Ubuntu system | ~800MB |
| FastAPI + Hermes | ~600MB |
| ChromaDB | ~400MB |
| sentence-transformers | ~500MB |
| Ollama llama3.2:3b | ~2.2GB |
| Docker (Postgres + Redis) | ~300MB |
| Next.js dev server | ~300MB |
| **Total** | **~5.1GB** |

Leaves ~5GB free for browser, VS Code, and Windows processes.

---

## Quick Reference

| Task | Command |
|------|---------|
| Restart WSL2 | `wsl --shutdown` (PowerShell) |
| Check WSLg display | `echo $DISPLAY` |
| Apply .wslconfig changes | `wsl --shutdown` → reopen |
| Backup WSL2 | `wsl --export Ubuntu-24.04 backup.tar` |
| Open VS Code in project | `cd ~/projects/samplemind && code .` |
| Launch dev environment | `dev` |
| Toggle tmux sessions | `Ctrl+B` → `s` |
| Check WSL2 IP | `ip addr show eth0` |

---

*ThinkPad X1 Carbon G8 — WSL2 Powerhouse + Tokyo Night — March 2026*
