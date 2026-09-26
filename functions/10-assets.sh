#!/usr/bin/env bash
# functions/10-assets.sh -- module name: "assets"
# Deploys shared image assets: wallpapers (for Noctalia's dynamic
# wallpaper-driven theming) and the fastfetch logo.
set -euo pipefail

write_module_header "Deploying wallpapers"
mkdir -p "$HOME/Pictures/Wallpapers"
cp -r "${DOTFILES_ROOT}/assets/wallpapers/." "$HOME/Pictures/Wallpapers/"
echo -e "\033[32m[SUCCESS] Wallpapers deployed to ~/Pictures/Wallpapers\033[0m"

write_module_header "Deploying fastfetch logo"
copy_dotfile "${DOTFILES_ROOT}/assets/fastfetch/logo.png" "$HOME/.config/fastfetch/logo.png"

# The Hyprland leg binds Mod+Shift+/ to `kitty -e less ~/.config/keybindings.txt`
# but nothing ever deployed that file.
write_module_header "Deploying keybindings cheatsheet"
copy_dotfile "${DOTFILES_ROOT}/assets/keybindings.txt" "$HOME/.config/keybindings.txt"
