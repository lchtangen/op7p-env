#!/usr/bin/env bash
# fix-zshrc-aliases.sh — Fix capitalised paths in /etc/zsh/zshrc.local
# Run from Termux with Magisk root:
#   su -c "bash /storage/emulated/0/dev/scripts/android/fix-zshrc-aliases.sh"
#
# What it does:
#   Replaces all capitalized path aliases (~/AI, ~/Dev, ~/Docs, ~/Recovery,
#   ~/Backups, ~/Workspace, ~/Projects) with the correct lowercase equivalents.
#   After this script runs, remove the override block from ~/.zshrc.

set -euo pipefail

FILE="/data/data/com.termux/files/home/.local/share/chroot-ubuntu/etc/zsh/zshrc.local"

# Adjust path if your chroot is mounted differently
if [[ ! -f "$FILE" ]]; then
  # Try common alternative mount points
  for candidate in \
    "/data/local/ubuntu/etc/zsh/zshrc.local" \
    "/data/ubuntu/etc/zsh/zshrc.local" \
    "/sdcard/../etc/zsh/zshrc.local"; do
    [[ -f "$candidate" ]] && FILE="$candidate" && break
  done
fi

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: Could not find zshrc.local. Set FILE= manually and re-run."
  exit 1
fi

echo "Patching: $FILE"
cp "$FILE" "${FILE}.bak-$(date +%Y%m%d%H%M%S)"

sed -i \
  -e "s|~/AI/notebooks|~/ai/notebooks|g" \
  -e "s|~/AI\b|~/ai|g" \
  -e "s|~/Dev/scripts|~/dev/scripts|g" \
  -e "s|~/Dev\b|~/dev|g" \
  -e "s|~/Docs\b|~/docs|g" \
  -e "s|~/Recovery\b|~/recovery|g" \
  -e "s|~/Backups/dotfiles|~/backups/dotfiles|g" \
  -e "s|~/Backups\b|~/backups|g" \
  -e "s|~/Workspace\b|~/workspace|g" \
  -e "s|~/Projects/active|~/projects|g" \
  -e "s|~/Projects/sandbox|~/projects|g" \
  -e "s|~/Projects\b|~/projects|g" \
  "$FILE"

echo "Done. Original backed up to ${FILE}.bak-*"
echo ""
echo "After verifying, remove the alias override block from ~/.zshrc"
echo "(the block between the 'Navigation alias overrides' and 'Login banner' comments)"
