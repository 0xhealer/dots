#!/usr/bin/env bash
# functions/06-fastfetch.sh — module name: "fastfetch"
set -euo pipefail

write_module_header "Deploying fastfetch config"
copy_dotfile "${DOTFILES_ROOT}/configs/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
copy_dotfile "${DOTFILES_ROOT}/configs/fastfetch/eagle-logo.txt" "$HOME/.config/fastfetch/eagle-logo.txt"
