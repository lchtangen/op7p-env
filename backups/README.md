# backups/ — System and Data Backups

Backup storage for configs, databases, and device state.

---

## What to Back Up

| Item | Command | Frequency |
|------|---------|-----------|
| dotfiles | `cp ~/.zshrc ~/.config/ ~/backups/dotfiles/` | After changes |
| nvim config | `cp -r ~/.config/nvim ~/backups/nvim/` | After changes |
| tmux config | `cp ~/.config/tmux/tmux.conf ~/backups/tmux/` | After changes |
| Ollama models | Not needed — `ollama pull` re-downloads | On new device |
| Android (TWRP) | TWRP → Backup → Boot + System + Data | Before kernel flash |
| Projects | `git push` to GitHub | Continuously |

---

## Android Full Backup (ADB)

```bash
# From PC:
adb backup -apk -shared -all -f oneplus7pro-$(date +%Y%m%d).ab

# Restore:
adb restore oneplus7pro-YYYYMMDD.ab
```

---

## Config Backup Script

```bash
mkdir -p ~/backups/dotfiles ~/backups/configs
cp ~/.zshrc ~/backups/dotfiles/
cp ~/.config/tmux/tmux.conf ~/backups/configs/
cp -r ~/.config/nvim/lua ~/backups/configs/nvim-lua/
tar -czf ~/backups/configs-$(date +%Y%m%d).tar.gz ~/backups/configs/
```
