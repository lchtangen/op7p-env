# Cyberpunk WSLg GUI Environment — ThinkPad X1 Carbon Gen 8
**System:** Windows 11 25H2 + WSL2 Ubuntu 24.04 LTS + WSLg  
**Purpose:** Native Linux GUI apps on Windows desktop with cyberpunk aesthetic  
**Scope:** Desktop environment · Development tools · UI/UX design workflow  
**Date:** March 2026

---

## What WSLg Is and Why It Changes Everything

WSLg (Windows Subsystem for Linux GUI) is a technology built into Windows 11 that allows Linux graphical applications to run natively on your Windows desktop — with no virtual machine window, no separate display, and no performance penalty. Linux GUI apps appear in your Windows taskbar, support copy-paste between environments, and use GPU-accelerated rendering through your Intel UHD 620.

The practical implication for your workflow is significant. You can run VS Code, your SampleMind Next.js frontend, a full Linux browser for testing, Figma alternatives, and audio tools — all as native-feeling Windows windows — while your underlying system architecture remains Linux. This is not emulation. It is a real Wayland compositor (Weston) running inside WSL2, projecting windows onto the Windows desktop via RDP.

---

## Phase 1 — Verify WSLg is Active

```bash
# Inside WSL2 Ubuntu terminal
echo $DISPLAY
# Should output: :0 or similar

echo $WAYLAND_DISPLAY
# Should output: wayland-0

# Test immediately — launch a GUI app
sudo apt install -y gedit
gedit &
# A Linux text editor window should appear on your Windows desktop
```

If `$DISPLAY` is empty, your `.wslconfig` may need the `guiApplications=true` line confirmed and WSL2 restarted via `wsl --shutdown` from PowerShell.

---

## Phase 2 — Install the Cyberpunk Desktop Layer

You are not installing a full desktop environment (no KDE or GNOME — those are resource-heavy and conflict with WSLg's compositor model). Instead, you are installing a curated set of GTK and Qt theming layers, a cyberpunk icon set, and a Wayland-compatible application launcher that makes every Linux GUI app you open look visually cohesive and professional.

### 2.1 — GTK Theme Engine and Dependencies

```bash
sudo apt update && sudo apt install -y \
  gtk2-engines-murrine \
  gtk2-engines-pixbuf \
  sassc \
  libglib2.0-dev-bin \
  git \
  papirus-icon-theme \
  fonts-jetbrains-mono \
  fonts-noto-color-emoji \
  dconf-cli \
  dconf-editor \
  gnome-themes-extra \
  libgtk-3-dev
```

### 2.2 — Tokyo Night GTK Theme (Cyberpunk Dark)

Tokyo Night is the most refined cyberpunk-adjacent GTK theme available for Linux. It uses a deep navy-black background (`#1a1b26`), electric blue accents (`#7aa2f7`), and cyan highlights (`#7dcfff`) — directly matching the aesthetic used in your development environment. It is maintained actively and covers GTK 3, GTK 4, and Qt applications uniformly.

```bash
# Clone and install Tokyo Night GTK theme
git clone https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme.git \
  ~/themes/tokyo-night
cd ~/themes/tokyo-night

# Install for current user (no sudo required)
mkdir -p ~/.local/share/themes
cp -r themes/Tokyonight-Dark-BL ~/.local/share/themes/
cp -r themes/Tokyonight-Dark-BL-LB ~/.local/share/themes/

# Install icon theme
mkdir -p ~/.local/share/icons
cp -r icons/Tokyonight-Dark ~/.local/share/icons/
```

### 2.3 — Apply the Theme Globally

Create or edit `~/.config/gtk-3.0/settings.ini`:

```ini
[Settings]
gtk-theme-name=Tokyonight-Dark-BL
gtk-icon-theme-name=Tokyonight-Dark
gtk-font-name=JetBrains Mono 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=16
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
```

Create `~/.config/gtk-4.0/settings.ini` with the same content.

Apply via dconf for immediate effect without logout:

```bash
dconf write /org/gnome/desktop/interface/gtk-theme "'Tokyonight-Dark-BL'"
dconf write /org/gnome/desktop/interface/icon-theme "'Tokyonight-Dark'"
dconf write /org/gnome/desktop/interface/font-name "'JetBrains Mono 11'"
dconf write /org/gnome/desktop/interface/monospace-font-name "'JetBrains Mono 13'"
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
```

### 2.4 — Qt Application Theming (Matches GTK)

Many developer tools (including some audio applications) use the Qt framework. Without theming, Qt apps will look jarring next to your themed GTK apps.

```bash
sudo apt install -y qt5-style-kvantum qt5ct

# Create Kvantum config directory
mkdir -p ~/.config/Kvantum

# Download Tokyo Night Kvantum theme
git clone https://github.com/mjkim0727/TokyoNight-Kvantum.git \
  ~/themes/tokyonight-kvantum
cp -r ~/themes/tokyonight-kvantum/TokyoNight ~/.config/Kvantum/

# Set Qt platform theme
echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> ~/.zshrc
echo 'export QT_STYLE_OVERRIDE=kvantum' >> ~/.zshrc
source ~/.zshrc
```

---

## Phase 3 — Essential GUI Applications for Development

### 3.1 — Thorium Browser — Fast Chromium for Linux Testing

Thorium is a performance-optimised Chromium fork with all Google telemetry removed. It is 8–38% faster than standard Chrome and the ideal browser for testing your SampleMind web frontend in a native Linux environment while your Windows Chrome tests the Windows-facing behaviour.

```bash
# Add Thorium repository
wget -q https://dl.thorium.rocks/debian/dists/stable/thorium.list \
  -O /tmp/thorium.list
sudo mv /tmp/thorium.list /etc/apt/sources.list.d/
sudo apt update && sudo apt install thorium-browser -y

# Launch
thorium-browser &
```

### 3.2 — Figma Linux (Electron) — UI/UX Design

```bash
# Install via Flatpak (most reliable method for Electron apps in WSLg)
sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub io.github.Figma_Linux -y

# Launch
flatpak run io.github.Figma_Linux &
```

### 3.3 — GIMP — Professional Image Editing

```bash
sudo apt install gimp -y

# Install cyberpunk-compatible dark theme for GIMP
mkdir -p ~/.config/GIMP/2.10/themes/
git clone https://github.com/Dirtmound/GIMP-themes.git /tmp/gimp-themes
cp -r /tmp/gimp-themes/Darkness ~/.config/GIMP/2.10/themes/

gimp &
```

### 3.4 — Inkscape — Vector Design for SampleMind Assets

```bash
sudo apt install inkscape -y
inkscape &
```

### 3.5 — Audacity — Audio Analysis for SampleMind Development

Audacity is essential for visually verifying that your Hermes feature extraction is behaving correctly — you can inspect spectrograms, waveforms, and frequency analysis of samples before and after pipeline processing.

```bash
sudo apt install audacity -y
audacity &
```

### 3.6 — DBeaver — Database GUI for SampleMind Database

```bash
# Download DBeaver Community
wget -O /tmp/dbeaver.deb \
  https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
sudo dpkg -i /tmp/dbeaver.deb
sudo apt install -f -y

dbeaver &
```

---

## Phase 4 — Terminal Enhancement for WSLg

Your terminal is the centrepiece of the cyberpunk environment. With WSLg, you can install a native Linux terminal emulator that looks and behaves better than the Windows Terminal for Linux-specific workflows.

### 4.1 — Alacritty — GPU-Accelerated Terminal

```bash
sudo apt install alacritty -y

# Create Alacritty config directory
mkdir -p ~/.config/alacritty
```

Create `~/.config/alacritty/alacritty.toml`:

```toml
[window]
padding = { x = 16, y = 12 }
decorations = "full"
opacity = 0.92
blur = true
title = "HERMES TERMINAL"
dynamic_title = true

[font]
normal = { family = "JetBrains Mono", style = "Regular" }
bold = { family = "JetBrains Mono", style = "Bold" }
italic = { family = "JetBrains Mono", style = "Italic" }
size = 13.0

[colors.primary]
background = "#0a0a0f"
foreground = "#c0caf5"

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

[colors.cursor]
text   = "#0a0a0f"
cursor = "#00f5ff"

[cursor]
style = { shape = "Beam", blinking = "Always" }
blink_interval = 500

[scrolling]
history = 50000
multiplier = 5

[keyboard]
bindings = [
  { key = "Return", mods = "Shift|Control", action = "SpawnNewInstance" },
  { key = "C", mods = "Control|Shift", action = "Copy" },
  { key = "V", mods = "Control|Shift", action = "Paste" }
]
```

### 4.2 — Neovim with Cyberpunk Theme

```bash
# Install latest Neovim (AppImage for most recent version)
wget -q https://github.com/neovim/neovim/releases/latest/download/nvim.appimage \
  -O ~/bin/nvim
chmod +x ~/bin/nvim
mkdir -p ~/bin
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Install NvChad (best modern Neovim config framework)
git clone https://github.com/NvChad/starter ~/.config/nvim --depth 1
nvim  # Run once — installs all plugins automatically
```

Inside Neovim, after initial setup, run `:Lazy sync` and then set theme via `:colorscheme tokyonight-night`.

---

## Phase 5 — Application Launcher and Desktop Integration

### 5.1 — Rofi — Cyberpunk Application Launcher

```bash
sudo apt install rofi -y
mkdir -p ~/.config/rofi
```

Create `~/.config/rofi/config.rasi`:

```css
configuration {
  modi: "drun,run,window";
  font: "JetBrains Mono 12";
  show-icons: true;
  icon-theme: "Tokyonight-Dark";
  terminal: "alacritty";
  drun-display-format: "{name}";
  display-drun: "LAUNCH";
  display-run: "EXECUTE";
  display-window: "SWITCH";
}

* {
  bg-col:         #0a0a0f;
  bg-col-light:   #1a1b26;
  border-col:     #00f5ff;
  selected-col:   #1a1b26;
  blue:           #7aa2f7;
  fg-col:         #c0caf5;
  fg-col2:        #7dcfff;
  grey:           #414868;
  accent:         #00f5ff;
}

window {
  background-color: @bg-col;
  border:           2px solid;
  border-color:     @accent;
  border-radius:    8px;
  width:            600px;
}

mainbox {
  background-color: @bg-col;
  children:         [ inputbar, listview ];
  spacing:          0px;
  padding:          12px;
}

inputbar {
  background-color: @bg-col-light;
  border:           0 0 1px 0;
  border-color:     @border-col;
  border-radius:    4px 4px 0 0;
  padding:          10px;
  children:         [ prompt, entry ];
}

prompt {
  background-color: @bg-col-light;
  padding:          0 8px 0 0;
  text-color:       @accent;
}

entry {
  background-color: @bg-col-light;
  text-color:       @fg-col;
  placeholder:      "search applications...";
  placeholder-color:@grey;
}

listview {
  background-color: @bg-col;
  columns:          1;
  lines:            8;
  padding:          8px 0;
}

element {
  background-color: @bg-col;
  text-color:       @fg-col;
  padding:          8px 12px;
  border-radius:    4px;
  spacing:          8px;
}

element selected {
  background-color: @selected-col;
  text-color:       @fg-col2;
  border:           0 0 0 2px;
  border-color:     @accent;
}

element-icon {
  size: 1.5em;
  background-color: transparent;
}

element-text {
  background-color: transparent;
  vertical-align:   0.5;
}
```

Launch Rofi from your WSL2 terminal:

```bash
# Add to .zshrc for quick keyboard trigger
alias launcher="rofi -show drun"
```

### 5.2 — Desktop Shortcut Integration with Windows

WSLg apps automatically appear in your Windows Start Menu under a "Ubuntu" section after first launch. To create Windows desktop shortcuts for your most-used Linux apps, run from PowerShell:

```powershell
# Creates a Windows .lnk shortcut for Alacritty
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut("$env:USERPROFILE\Desktop\Alacritty (WSL).lnk")
$Shortcut.TargetPath = "wsl.exe"
$Shortcut.Arguments = "-- /home/USERNAME/bin/alacritty"
$Shortcut.IconLocation = "%SystemRoot%\System32\bash.exe"
$Shortcut.Save()
```

---

## Phase 6 — Fonts and Visual Polish

### 6.1 — Install the Complete JetBrains Mono + Nerd Font

The standard JetBrains Mono package in Ubuntu does not include Nerd Font symbols (icons used by Powerlevel10k, exa, and development tools). Install the complete Nerd Font version:

```bash
mkdir -p ~/.local/share/fonts/JetBrainsMono
cd ~/.local/share/fonts/JetBrainsMono

wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
  -O /tmp/JetBrainsMono.zip
unzip -q /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono

# Refresh font cache
fc-cache -fv

# Verify installation
fc-list | grep "JetBrains"
```

Update Alacritty config to use the Nerd Font variant:

```bash
sed -i 's/JetBrains Mono/JetBrainsMono Nerd Font/g' ~/.config/alacritty/alacritty.toml
```

### 6.2 — Compositor Effects (Transparency and Blur)

WSLg uses Weston as its compositor. To enable window transparency for your terminal and application windows:

```bash
# Create Weston config
mkdir -p ~/.config
cat > ~/.config/weston.ini << 'EOF'
[core]
use-g2d=1

[shell]
background-color=0x00000000
panel-position=none

[keyboard]
numlock-on=true
EOF
```

---

## Phase 7 — Development Workflow Integration

### 7.1 — The Complete Cyberpunk Dev Stack Launch Script

Create `~/bin/devenv`:

```bash
#!/bin/bash
# HERMES DEVELOPMENT ENVIRONMENT LAUNCHER
# Starts all services and opens the development workspace

echo "⚡ Initialising SampleMind development environment..."

# Start backend services
sudo systemctl start ollama 2>/dev/null && echo "✓ Ollama LLM runtime started"
docker start chromadb 2>/dev/null && echo "✓ ChromaDB vector database started"
docker start open-webui 2>/dev/null && echo "✓ OpenWebUI interface started"

# Open development workspace
sleep 2

# Launch terminals in tmux
tmux new-session -d -s dev -n "backend"
tmux send-keys -t dev:backend "cd ~/projects/samplemind && source ~/envs/samplemind/bin/activate && echo 'SampleMind AI env active'" C-m
tmux new-window -t dev -n "frontend"
tmux send-keys -t dev:frontend "cd ~/projects/samplemind-web && pnpm dev" C-m
tmux new-window -t dev -n "logs"
tmux send-keys -t dev:logs "docker logs -f chromadb" C-m

# Open Alacritty attached to the tmux session
alacritty -e tmux attach-session -t dev &

# Open browser tabs
thorium-browser \
  http://localhost:3000 \
  http://localhost:8080 \
  http://localhost:8000/docs \
  http://localhost:8888 &

echo "✓ Development environment ready."
echo "  SampleMind Web:  http://localhost:3000"
echo "  FastAPI Docs:    http://localhost:8000/docs"
echo "  OpenWebUI:       http://localhost:8080"
echo "  Jupyter Lab:     http://localhost:8888"
```

```bash
chmod +x ~/bin/devenv
echo 'alias dev="~/bin/devenv"' >> ~/.zshrc
source ~/.zshrc

# Launch everything with one command
dev
```

### 7.2 — VS Code WSLg Integration

VS Code on Windows with the Remote - WSL extension already runs inside WSL2. For a pure Linux VS Code instance that opens as a WSLg window:

```bash
# Install VS Code Server inside WSL2 for native GUI mode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > \
  packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg \
  /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
  https://packages.microsoft.com/repos/code stable main" | \
  sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update && sudo apt install code -y

# Launch Linux VS Code as a WSLg window
code ~/projects/samplemind &
```

---

## Quick Reference — Cyberpunk Application Commands

```bash
# Launch core GUI applications
alacritty &           # Cyberpunk terminal
thorium-browser &     # Linux browser
inkscape &            # Vector design
gimp &                # Image editing
audacity &            # Audio analysis
dbeaver &             # Database GUI
code . &              # VS Code (Linux native)
rofi -show drun       # App launcher

# Development environment
dev                   # Start full dev stack
tmux attach -t dev    # Re-attach to dev session

# Theming
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
```

---

## Colour Reference — Tokyo Night Palette

| Name | Hex | Usage |
|---|---|---|
| Background | `#0a0a0f` | Terminal and window backgrounds |
| Surface | `#1a1b26` | Cards, panels, sidebars |
| Border | `#414868` | Inactive borders |
| Accent Cyan | `#00f5ff` | Primary accent, borders, cursor |
| Blue | `#7aa2f7` | Functions, links |
| Purple | `#bb9af7` | Keywords, types |
| Cyan | `#7dcfff` | Strings, constants |
| Green | `#9ece6a` | Success states, variables |
| Yellow | `#e0af68` | Warnings, attributes |
| Red | `#f7768e` | Errors, destructive actions |
| Foreground | `#c0caf5` | Primary text |
| Muted | `#565f89` | Comments, secondary text |

This palette is consistent across your Alacritty terminal, GTK applications, Qt applications, VS Code (Tokyo Night theme), Neovim, and your SampleMind web frontend's Tailwind CSS configuration — creating a fully unified visual environment across every surface of your development workflow.

---

*ThinkPad X1 Carbon Gen 8 — WSLg Cyberpunk Environment | March 2026*  
*Unified with SampleMind AI development stack*
