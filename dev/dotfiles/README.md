# dev/dotfiles/ — Dotfile Backups and Templates

Tracked dotfiles for reproducible environment setup across devices.

---

## Contents (when populated)

```
dotfiles/
├── .zshrc              zsh user config
├── .gitconfig          git global config
├── nvim/               Neovim config (symlink from ~/.config/nvim)
└── tmux.conf           tmux config
```

---

## Backup Commands (aliases in ~/.zshrc)

```bash
bak-zsh     # cp ~/.zshrc ~/backups/dotfiles/.zshrc.bak
bak-nvim    # cp -r ~/.config/nvim ~/backups/dotfiles/nvim
bak-tmux    # cp ~/.config/tmux/tmux.conf ~/backups/dotfiles/tmux.conf
```

The full Neovim and tmux configs are tracked at:
- `~/.config/nvim/` (in this repo under `.config/nvim/`)
- `~/.config/tmux/tmux.conf` (in this repo under `.config/tmux/`)
