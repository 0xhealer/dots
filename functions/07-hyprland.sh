#!/usr/bin/env bash
# functions/07-hyprland.sh -- module name: "hyprland"
set -euo pipefail

write_module_header "Deploying Hyprland config"
copy_dotfile "${DOTFILES_ROOT}/configs/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"

echo "!! This is the Lua config (Hyprland 0.55+, current stable) -- if your installed Hyprland is older, get hyprland.lua support first or this won't load"
echo "!! Autostarts Noctalia via 'qs -c noctalia-shell' (v4 syntax) -- run functions/09-noctalia.sh and confirm the installed version before relying on this"
