#!/usr/bin/env bash
# functions/07-hyprland.sh -- module name: "hyprland"
set -euo pipefail

write_module_header "Deploying Hyprland config"
copy_dotfile "${DOTFILES_ROOT}/configs/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"

if ! test_command_exists Hyprland; then
    echo -e "\033[33m[WARN] Hyprland is not installed (it is not in packages/pacman.txt) -- config deployed, but install it with 'sudo pacman -S hyprland' before choosing that session\033[0m"
fi

echo "!! This is the Lua config (Hyprland 0.55+, current stable) -- if your installed Hyprland is older, get hyprland.lua support first or this won't load"
echo "!! Autostarts Noctalia v5 via 'noctalia' (no flag -- confirmed from Hyprland-specific v5 docs) -- run functions/09-noctalia.sh (installs the package + config.toml) if you haven't already"
