# ThinkPad X1 Carbon Gen 8 — WSL2 Powerhouse Development Setup
**Device:** ThinkPad X1 Carbon Gen 8 | i5-10310U | 16GB RAM | 256GB NVMe  
**OS:** Windows 11 Pro 25H2 + WSL2 Ubuntu 24.04 LTS  
**Purpose:** AI Development · App Development · UI/UX · Music Production  
**Last Updated:** March 2026

---

## Table of Contents

1. [Phase 0 — Windows 11 Optimisation](#phase-0)
2. [Phase 1 — WSL2 Installation and Configuration](#phase-1)
3. [Phase 2 — Ubuntu 24.04 Environment Setup](#phase-2)
4. [Phase 3 — Python AI and SampleMind Stack](#phase-3)
5. [Phase 4 — Web and App Development Stack](#phase-4)
6. [Phase 5 — Local AI and LLM Inference](#phase-5)
7. [Phase 6 — VS Code Power Configuration](#phase-6)
8. [Phase 7 — System Performance Tuning](#phase-7)
9. [Phase 8 — Security and Privacy Hardening](#phase-8)
10. [Phase 9 — Developer Tools and CLI Enhancement](#phase-9)
11. [Phase 10 — Dual Boot Preparation for Ubuntu](#phase-10)
12. [Hardware Reference and Limits](#hardware-reference)

---

## Phase 0 — Windows 11 Optimisation {#phase-0}

Complete these steps immediately after Windows 11 installation, before installing anything else. This foundation determines the performance of everything above it.

### 0.1 — Lenovo Vantage Driver and Firmware Updates

Open Microsoft Store → search **Lenovo Vantage** → install → open and run System Update. Install all updates in this exact priority order:

1. BIOS/Firmware update (critical — unlocks full hardware capability)
2. Intel UHD 620 graphics driver
3. Thunderbolt firmware
4. Intel Wi-Fi 6 AX201 driver
5. Touchpad and touchscreen drivers
6. All remaining updates

Reboot after every firmware-level update. Do not skip the BIOS update — it contains power management improvements essential for development workloads on your i5-10310U.

### 0.2 — Windows 11 Performance Settings

```powershell
# Run PowerShell as Administrator

# Set power plan to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Disable hibernation to free SSD space (saves ~8GB on 16GB RAM machine)
powercfg /hibernate off

# Enable long paths (required for many Node.js and Python projects)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1

# Enable developer mode
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /d "1" /f /v "AllowDevelopmentWithoutDevLicense"
```

### 0.3 — Disable Unnecessary Windows Services

Open **Services** (Win + R → `services.msc`) and set the following to **Disabled** to free RAM and CPU for your development workloads:

| Service | Reason to Disable |
|---|---|
| Windows Search (indexing) | High disk I/O, unnecessary with WSL2 |
| SysMain (Superfetch) | Aggressive RAM preloading, counterproductive with dev workloads |
| Xbox Game Bar | Background resource usage |
| Print Spooler | Unless you use a printer |
| Fax | Never needed |

### 0.4 — Visual Performance — Disable Animations

Control Panel → System → Advanced System Settings → Performance → **Adjust for best performance**. Then re-enable only:
- Smooth edges of screen fonts
- Show thumbnails instead of icons

This recovers approximately 150–300MB RAM and reduces CPU overhead significantly on integrated graphics.

### 0.5 — Windows Defender Exclusions (Critical for Development)

Windows Defender scanning your WSL2 filesystem, Node modules, and Python packages causes severe performance degradation. Add exclusions in **Windows Security → Virus & threat protection → Exclusions**:

```
C:\Users\[YourUsername]\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu*
\\wsl$\Ubuntu-24.04\
C:\Users\[YourUsername]\AppData\Local\Temp
```

> ⚠️ Only exclude known development paths. Do not exclude your entire C: drive.

---

## Phase 1 — WSL2 Installation and Configuration {#phase-1}

### 1.1 — Install WSL2 with Ubuntu 24.04 LTS

Open **PowerShell as Administrator**:

```powershell
# Install WSL2 with Ubuntu 24.04 LTS
wsl --install -d Ubuntu-24.04

# Verify WSL2 is the default version
wsl --set-default-version 2

# After reboot, verify installation
wsl --list --verbose
# Should show: Ubuntu-24.04  Running  2
```

### 1.2 — WSL2 Global Configuration

Create the WSL2 global config file at `C:\Users\[YourUsername]\.wslconfig`:

```ini
[wsl2]
# Memory allocation — 10GB for WSL2, leaving 6GB for Windows + FL Studio
memory=10GB

# CPU cores — give WSL2 access to all 4 cores (8 threads)
processors=4

# Swap space on your NVMe — acts as virtual RAM for large AI models
swap=8GB

# Enable nested virtualisation (required for Docker and some dev tools)
nestedVirtualization=true

# Faster localhost networking
localhostForwarding=true

# GUI app support (WSLg — runs Linux GUI apps natively on Windows desktop)
guiApplications=true

# Kernel command line optimisations
kernelCommandLine=quiet splash

[experimental]
# Auto-release memory back to Windows when WSL2 is idle
autoMemoryReclaim=gradual

# Sparse VHD — prevents the WSL2 virtual disk from growing unnecessarily
sparseVhd=true
```

> 💡 **Why 10GB for WSL2?** Your i5-10310U with 16GB total RAM needs a clear split. FL Studio on Windows performs best with 4–6GB available. WSL2 with Python AI workloads, Node.js builds, and Ollama LLM inference benefits enormously from 10GB. The `autoMemoryReclaim` setting ensures the memory returns to Windows when you switch to music production.

### 1.3 — WSL2 Per-Distribution Configuration

Inside Ubuntu, create `/etc/wsl.conf`:

```bash
sudo nano /etc/wsl.conf
```

```ini
[boot]
# Run systemd inside WSL2 — enables proper service management
systemd=true

# Commands to run on WSL2 start
command="sysctl -w vm.swappiness=10"

[automount]
# Mount Windows drives with correct permissions for development
enabled=true
root=/mnt/
options="metadata,umask=22,fmask=11"
mountFsTab=true

[network]
# Keep a consistent hostname
hostname=thinkpad-dev

# Generate /etc/hosts automatically
generateHosts=true
generateResolvConf=true

[interop]
# Allow launching Windows executables from WSL2
enabled=true
appendWindowsPath=true
```

### 1.4 — Restart WSL2 to Apply Config

```powershell
# In PowerShell
wsl --shutdown
# Wait 8 seconds, then reopen Ubuntu terminal
```

---

## Phase 2 — Ubuntu 24.04 Environment Setup {#phase-2}

All commands from this point are run inside your **WSL2 Ubuntu terminal** unless stated otherwise.

### 2.1 — System Update and Essential Packages

```bash
# Full system update
sudo apt update && sudo apt upgrade -y

# Essential build tools and libraries
sudo apt install -y \
  build-essential \
  git \
  curl \
  wget \
  unzip \
  zip \
  htop \
  tree \
  jq \
  net-tools \
  openssh-client \
  gnupg \
  lsb-release \
  ca-certificates \
  software-properties-common \
  apt-transport-https \
  libssl-dev \
  libffi-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  liblzma-dev \
  libpq-dev \
  ffmpeg \
  libsndfile1-dev \
  portaudio19-dev
```

> 💡 `ffmpeg` and `libsndfile1` are essential for SampleMind AI's audio processing pipeline. Installing them now prevents dependency errors later.

### 2.2 — Zsh + Oh My Zsh — Professional Shell Environment

```bash
# Install Zsh
sudo apt install -y zsh

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10k theme (fast, informative, cyberpunk-compatible)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install essential plugins
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone https://github.com/zsh-users/zsh-completions \
  ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
```

Edit `~/.zshrc`:

```bash
# Set theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  docker
  python
  node
  sudo
  history
  colored-man-pages
)
```

```bash
# Set Zsh as default shell
chsh -s $(which zsh)
source ~/.zshrc
```

### 2.3 — Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
git config --global pull.rebase false

# Generate SSH key for GitHub
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519

# Display public key to add to GitHub
cat ~/.ssh/id_ed25519.pub
```

Add the displayed public key to **GitHub → Settings → SSH Keys**.

---

## Phase 3 — Python AI and SampleMind Stack {#phase-3}

### 3.1 — pyenv — Python Version Manager

```bash
# Install pyenv
curl https://pyenv.run | bash

# Add to ~/.zshrc (paste at bottom)
echo '
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc

source ~/.zshrc

# Install Python 3.11.9 (stable, best ML framework compatibility)
pyenv install 3.11.9
pyenv global 3.11.9

# Verify
python --version  # Should output: Python 3.11.9
```

### 3.2 — SampleMind AI Virtual Environment

```bash
# Create dedicated environment
python -m venv ~/envs/samplemind
source ~/envs/samplemind/bin/activate

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Core AI and audio processing stack
pip install \
  torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu \
  numpy \
  pandas \
  scikit-learn \
  librosa \
  soundfile \
  essentia \
  audioread \
  resampy \
  onnx \
  onnxruntime \
  transformers \
  datasets \
  accelerate

# SampleMind development tools
pip install \
  fastapi \
  uvicorn \
  sqlalchemy \
  alembic \
  pydantic \
  python-multipart \
  httpx \
  rich \
  typer \
  click \
  python-dotenv \
  pytest \
  black \
  ruff \
  mypy

# Save requirements
pip freeze > ~/samplemind-requirements.txt
```

### 3.3 — Add Environment to Shell

```bash
# Add convenient alias to ~/.zshrc
echo '
# SampleMind environment
alias sm="source ~/envs/samplemind/bin/activate"
alias smdev="cd ~/projects/samplemind && source ~/envs/samplemind/bin/activate"' >> ~/.zshrc
```

### 3.4 — Jupyter Lab for AI Experimentation

```bash
source ~/envs/samplemind/bin/activate

pip install jupyterlab ipywidgets ipykernel

# Register the samplemind kernel
python -m ipykernel install --user --name samplemind --display-name "SampleMind AI"

# Launch Jupyter Lab (opens in Windows browser automatically via WSLg)
jupyter lab --no-browser --port=8888
```

Access at `http://localhost:8888` in your Windows browser.

---

## Phase 4 — Web and App Development Stack {#phase-4}

### 4.1 — Node.js via nvm

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc

# Install Node.js LTS (v22.x as of 2026)
nvm install --lts
nvm use --lts
nvm alias default node

# Verify
node --version
npm --version

# Install global development tools
npm install -g \
  pnpm \
  yarn \
  typescript \
  ts-node \
  @types/node \
  eslint \
  prettier \
  nodemon \
  concurrently \
  serve
```

### 4.2 — SampleMind Web Dashboard (Next.js + TypeScript)

```bash
mkdir -p ~/projects
cd ~/projects

# Create Next.js project with full TypeScript and Tailwind CSS
npx create-next-app@latest samplemind-web \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*"

cd samplemind-web

# Install UI and visualisation dependencies
pnpm add \
  @radix-ui/react-dialog \
  @radix-ui/react-dropdown-menu \
  @radix-ui/react-toast \
  lucide-react \
  recharts \
  framer-motion \
  clsx \
  tailwind-merge \
  class-variance-authority \
  zustand \
  @tanstack/react-query \
  axios

# Run development server
pnpm dev
```

Access at `http://localhost:3000` in your Windows browser.

### 4.3 — Tauri — Desktop App Framework for SampleMind

Tauri will be your desktop application layer for SampleMind. It uses your web frontend (React/Next.js) with a Rust backend, producing a native app that is 10–20x smaller than Electron alternatives.

```bash
# Install Rust (required by Tauri)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install Tauri CLI
cargo install tauri-cli

# Install system dependencies for Tauri on Linux
sudo apt install -y \
  libwebkit2gtk-4.1-dev \
  build-essential \
  curl \
  wget \
  file \
  libxdo-dev \
  libssl-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev

# Create a Tauri project (run inside your web project folder)
cd ~/projects/samplemind-web
cargo tauri init
```

### 4.4 — Docker — Containerisation for Development

```bash
# Install Docker inside WSL2 Ubuntu
sudo apt install -y docker.io docker-compose-plugin

# Add your user to the docker group
sudo usermod -aG docker $USER

# Enable Docker service via systemd
sudo systemctl enable docker
sudo systemctl start docker

# Verify
docker --version
docker compose version

# Test
docker run hello-world
```

> 💡 Docker inside WSL2 with systemd enabled gives you full container capability without Docker Desktop on Windows. This is faster, uses less memory, and is the professional standard setup for Linux development.

---

## Phase 5 — Local AI and LLM Inference {#phase-5}

### 5.1 — Ollama — Local LLM Runtime

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Enable as a background service
sudo systemctl enable ollama
sudo systemctl start ollama

# Pull recommended models for your hardware (i5-10310U, 16GB RAM)
# These are balanced for your CPU-only inference capability

# 7B parameter models — best for code assistance and SampleMind logic
ollama pull llama3.2:3b          # Fast, lightweight — daily use
ollama pull mistral:7b           # Best for code generation
ollama pull codellama:7b         # Specialised code model
ollama pull nomic-embed-text     # Text embeddings for SampleMind search

# Verify models are available
ollama list
```

### 5.2 — OpenWebUI — Browser Interface for Local LLMs

```bash
# Run OpenWebUI via Docker (connects to your local Ollama)
docker run -d \
  --name open-webui \
  --network=host \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://localhost:11434 \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Access at `http://localhost:8080` — this gives you a ChatGPT-style interface for all your local models, running entirely offline.

### 5.3 — LangChain for SampleMind AI Pipeline Integration

```bash
source ~/envs/samplemind/bin/activate

pip install \
  langchain \
  langchain-community \
  langchain-ollama \
  chromadb \
  sentence-transformers \
  faiss-cpu
```

### 5.4 — ChromaDB — Vector Database for Audio Embeddings

ChromaDB is the persistence layer for SampleMind's audio embedding search. It stores the AI-generated fingerprints of your audio samples and enables semantic search — finding samples by sound character rather than filename.

```bash
# ChromaDB runs as a persistent service
docker run -d \
  --name chromadb \
  -p 8001:8000 \
  -v ~/data/chromadb:/chroma/chroma \
  --restart always \
  chromadb/chroma:latest
```

---

## Phase 6 — VS Code Power Configuration {#phase-6}

### 6.1 — Essential Extensions

Install these extensions in VS Code (they will automatically apply inside WSL2 via Remote - WSL):

```
Remote - WSL                    — ms-vscode-remote.remote-wsl
Python                          — ms-python.python
Pylance                         — ms-python.vscode-pylance
Black Formatter                 — ms-python.black-formatter
Ruff                            — charliermarsh.ruff
Jupyter                         — ms-toolsai.jupyter
ESLint                          — dbaeumer.vscode-eslint
Prettier                        — esbenp.prettier-vscode
Tailwind CSS IntelliSense       — bradlc.vscode-tailwindcss
TypeScript Hero                 — ms-vscode.vscode-typescript-next
GitLens                         — eamodio.gitlens
GitHub Copilot                  — github.copilot
Docker                          — ms-azuretools.vscode-docker
Thunder Client (API testing)    — rangav.vscode-thunder-client
Error Lens                      — usernamehw.errorlens
Path Intellisense               — christian-kohler.path-intellisense
Auto Rename Tag                 — formulahendry.auto-rename-tag
```

### 6.2 — VS Code Settings JSON

Open **Settings → Open Settings JSON** (Ctrl + Shift + P → "Open User Settings JSON"):

```json
{
  "editor.fontSize": 14,
  "editor.fontFamily": "'JetBrains Mono', 'Fira Code', monospace",
  "editor.fontLigatures": true,
  "editor.lineHeight": 1.6,
  "editor.tabSize": 2,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.minimap.enabled": false,
  "editor.smoothScrolling": true,
  "editor.cursorBlinking": "phase",
  "editor.cursorSmoothCaretAnimation": "on",
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "editor.inlineSuggest.enabled": true,
  "editor.suggestSelection": "first",
  "workbench.colorTheme": "One Dark Pro",
  "workbench.iconTheme": "material-icon-theme",
  "workbench.startupEditor": "none",
  "terminal.integrated.defaultProfile.linux": "zsh",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.fontFamily": "'JetBrains Mono'",
  "python.defaultInterpreterPath": "~/envs/samplemind/bin/python",
  "python.formatting.provider": "black",
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "git.autofetch": true,
  "git.confirmSync": false,
  "explorer.compactFolders": false,
  "files.autoSave": "onFocusChange",
  "remote.WSL.fileWatcher.polling": false
}
```

---

## Phase 7 — System Performance Tuning {#phase-7}

### 7.1 — Linux Kernel Parameters for Development

Add to `/etc/sysctl.conf` inside WSL2:

```bash
sudo nano /etc/sysctl.conf
```

```ini
# Reduce swap aggressiveness — keeps more in RAM
vm.swappiness=10

# Increase file watcher limit — essential for Next.js and large Node projects
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512

# Improve network performance for local API development
net.core.somaxconn=65535
net.ipv4.tcp_fastopen=3

# Reduce dirty page writeback — better NVMe SSD longevity
vm.dirty_ratio=15
vm.dirty_background_ratio=5
```

```bash
# Apply immediately without reboot
sudo sysctl -p
```

### 7.2 — NVMe SSD Health and Performance

```bash
# Check NVMe health inside WSL2
sudo apt install nvme-cli -y
sudo nvme smart-log /dev/nvme0

# Enable TRIM for SSD longevity
sudo systemctl enable fstrim.timer
sudo fstrim -v /
```

### 7.3 — Zram — Compressed RAM (Recovers ~2GB Effective Memory)

```bash
sudo apt install zram-tools -y

sudo nano /etc/default/zramswap
# Set:
# ALGO=zstd
# PERCENT=25

sudo systemctl restart zramswap
# Verify
zramctl
```

> 💡 Zram compresses data in RAM before swapping. On your 16GB system this effectively gives you an additional 2–3GB of usable memory for free, with no SSD wear. Critical for running Ollama models alongside your development stack simultaneously.

---

## Phase 8 — Security and Privacy Hardening {#phase-8}

### 8.1 — SSH Hardening

```bash
# Generate strong SSH key if not already done
ssh-keygen -t ed25519 -a 100 -C "thinkpad-dev-$(date +%Y)"

# Configure SSH client
nano ~/.ssh/config
```

```
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 3
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  HashKnownHosts yes
```

### 8.2 — GPG Key for Git Commit Signing

```bash
# Generate GPG key
gpg --full-generate-key
# Choose: RSA and RSA, 4096 bits, 0 (no expiry), enter your name and email

# Get your key ID
gpg --list-secret-keys --keyid-format LONG

# Configure Git to sign commits
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
git config --global gpg.program gpg

# Export public key to add to GitHub
gpg --armor --export YOUR_KEY_ID
```

### 8.3 — Fail2ban and UFW Firewall (for WSL2 services)

```bash
# Install and configure UFW
sudo apt install ufw fail2ban -y

# Default deny incoming, allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh

# Allow development ports
sudo ufw allow 3000  # Next.js
sudo ufw allow 8000  # FastAPI
sudo ufw allow 8080  # OpenWebUI
sudo ufw allow 8888  # Jupyter

sudo ufw enable
sudo ufw status
```

---

## Phase 9 — Developer Tools and CLI Enhancement {#phase-9}

### 9.1 — Modern CLI Replacements

```bash
# Install modern alternatives to standard Unix tools
sudo apt install -y \
  bat \        # Better cat with syntax highlighting
  ripgrep \    # Faster grep (rg command)
  fd-find \    # Better find
  fzf \        # Fuzzy finder — extremely powerful
  exa \        # Better ls with colours and tree view
  tldr \       # Simplified man pages
  ncdu \       # Disk usage analyser

# Add aliases to ~/.zshrc
echo '
# Modern CLI aliases
alias cat="bat"
alias ls="exa --icons"
alias ll="exa -la --icons --git"
alias lt="exa --tree --icons --level=2"
alias grep="rg"
alias find="fdfind"
alias du="ncdu"' >> ~/.zshrc
```

### 9.2 — tmux — Terminal Multiplexer

tmux lets you run multiple terminal sessions inside one window and keeps processes running even when the terminal is closed — essential for running Ollama, Jupyter, and your API server simultaneously.

```bash
sudo apt install tmux -y

# Create tmux config
nano ~/.tmux.conf
```

```bash
# ~/.tmux.conf — Optimised for development
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Split panes with | and -
bind | split-window -h
bind - split-window -v

# Enable mouse support
set -g mouse on

# Status bar
set -g status-style bg=#1a1b26,fg=#7aa2f7
set -g status-left "#[fg=#7dcfff][#S] "
set -g status-right "#[fg=#9ece6a]%H:%M #[fg=#7aa2f7]%d/%m/%Y"

# Larger history
set -g history-limit=50000

# Fast escape for Vim/Neovim
set -sg escape-time 0
```

### 9.3 — Useful Development Aliases

```bash
cat >> ~/.zshrc << 'EOF'

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias proj="cd ~/projects"
alias sm="cd ~/projects/samplemind && source ~/envs/samplemind/bin/activate"

# Git shortcuts
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias gco="git checkout"

# Docker shortcuts
alias dps="docker ps"
alias dpa="docker ps -a"
alias dl="docker logs -f"
alias dex="docker exec -it"

# WSL2 utilities
alias winpath="explorer.exe ."
alias clip="clip.exe"

# Python
alias python="python3"
alias pip="pip3"
alias venv="python -m venv"

# Services
alias start-ollama="sudo systemctl start ollama"
alias start-chroma="docker start chromadb"
alias start-webui="docker start open-webui"
alias dev-stack="start-ollama && start-chroma && start-webui && echo 'Dev stack started'"

EOF
source ~/.zshrc
```

### 9.4 — Neovim — Powerful Terminal Editor (Optional but Recommended)

```bash
# Install latest Neovim
sudo apt install neovim -y

# Install NvChad — best Neovim config for developers
git clone https://github.com/NvChad/starter ~/.config/nvim --depth 1
nvim  # Run once to trigger plugin installation
```

---

## Phase 10 — Dual Boot Ubuntu Preparation {#phase-10}

When you are ready to add native Ubuntu alongside Windows 11, plan this carefully given your 256GB SSD constraint.

### 10.1 — Recommended Partition Layout

| Partition | Size | Filesystem | Purpose |
|---|---|---|---|
| EFI System | 260MB | FAT32 | Already exists from Windows |
| Windows Recovery | 600MB | NTFS | Already exists from Windows |
| Windows C: | 130GB | NTFS | Windows 11 + FL Studio |
| Ubuntu root `/` | 60GB | ext4 | Ubuntu system + applications |
| Ubuntu home `/home` | 55GB | ext4 | All development projects |
| Swap | 8GB | swap | Hibernation support |

> ⚠️ **Do not resize partitions while Windows is running.** Use the Ubuntu installer's partition manager or GParted from a live USB. Always back up your WSL2 environment first:
> ```powershell
> wsl --export Ubuntu-24.04 C:\Backup\ubuntu-backup.tar
> ```

### 10.2 — Pre-Dual-Boot Checklist

Before installing Ubuntu natively, complete these steps from within Windows:

```powershell
# 1. Disable Fast Startup (prevents NTFS corruption)
powercfg /hibernate off

# 2. Disable BitLocker if enabled
manage-bde -status C:

# 3. Check and fix Windows filesystem
chkdsk C: /f

# 4. Shrink Windows partition in Disk Management
# Win + X → Disk Management → Right-click C: → Shrink Volume
# Shrink by exactly 123904MB (121GB for Ubuntu + swap)
```

### 10.3 — GRUB Configuration After Ubuntu Install

After installing Ubuntu, GRUB will automatically detect Windows 11 and create a boot menu. To customise:

```bash
sudo nano /etc/default/grub

# Recommended settings:
GRUB_DEFAULT=0              # Ubuntu boots by default
GRUB_TIMEOUT=5              # 5 second menu timeout
GRUB_TIMEOUT_STYLE=menu     # Always show menu
```

```bash
sudo update-grub
```

---

## Hardware Reference and Limits {#hardware-reference}

### ThinkPad X1 Carbon Gen 8 (2021 Build) — Confirmed Specifications

| Component | Specification | Development Impact |
|---|---|---|
| CPU | Intel i5-10310U (4C/8T, 1.7–4.4GHz) | Good for Python, Node, Docker; limited for large LLM training |
| RAM | 16GB LPDDR3 (soldered, not upgradeable) | Maximum model size for Ollama: 7B parameter models |
| NVMe | 256GB Toshiba KXG6AZNV256G | NVMe speed sufficient; monitor free space carefully |
| GPU | Intel UHD 620 (shared RAM) | CPU-only AI inference; ONNX Runtime with OpenVINO for acceleration |
| Display | 14" FHD IPS + Touch | Full WSLg GUI app support |
| WiFi | Intel Wi-Fi 6 AX201 | Fast enough for all package downloads and cloud sync |
| Thunderbolt | Intel Thunderbolt 3 (2x ports) | External GPU enclosure possible in future (eGPU via TB3) |

### Performance Benchmarks to Expect

| Workload | Expected Speed |
|---|---|
| Ollama Llama3.2 3B inference | ~8–12 tokens/second |
| Ollama Mistral 7B inference | ~3–5 tokens/second |
| Next.js cold build | ~15–25 seconds |
| Python audio feature extraction (1 file) | ~0.5–2 seconds |
| Docker image pull | Fast (NVMe + Wi-Fi 6) |
| pytest full test suite (SampleMind) | ~10–30 seconds |

### Storage Budget (256GB SSD)

| Allocation | Size |
|---|---|
| Windows 11 + Drivers | ~30GB |
| FL Studio + Plugins + Samples | ~25GB |
| WSL2 Ubuntu VHD | ~25GB |
| Ollama Models (2–3 models) | ~15GB |
| Projects and Data | ~30GB |
| **Total Used** | **~125GB** |
| **Available for Growth** | **~131GB** |

> ⚠️ FL Studio sample libraries grow fast. Consider a USB-C external SSD (Samsung T7, 1TB, ~700 NOK) for sample storage to keep your NVMe free for system and development work.

---

## Quick Start Commands Reference

```bash
# Start full development stack
dev-stack

# Open SampleMind project
smdev

# Start Jupyter Lab
jupyter lab --no-browser --port=8888

# Start SampleMind FastAPI backend
uvicorn main:app --reload --port 8000

# Start SampleMind web frontend
cd ~/projects/samplemind-web && pnpm dev

# Chat with local AI
open http://localhost:8080

# Check system resources
htop

# List running Docker services
dps

# Backup WSL2 (run from PowerShell)
wsl --export Ubuntu-24.04 C:\Backup\ubuntu-$(date +%Y%m%d).tar
```

---

*ThinkPad X1 Carbon Gen 8 — WSL2 Powerhouse Setup | March 2026*  
*Next step: SampleMind AI Hermes tagging implementation*
