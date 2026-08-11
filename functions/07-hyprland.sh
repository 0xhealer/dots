#!/usr/bin/env bash
# functions/07-hyprland.sh -- module name: "hyprland"
set -euo pipefail

write_module_header "Deploying Hyprland config"
copy_dotfile "${DOTFILES_ROOT}/configs/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"

echo "!! Hyprland leg autostarts Noctalia via 'qs -c noctalia-shell' (v4 syntax) -- run functions/09-noctalia.sh and confirm the installed version before relying on this"
