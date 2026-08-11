#!/usr/bin/env bash
# functions/05-nvim.sh — module name: "nvim"
set -euo pipefail

write_module_header "Deploying nvim config"
copy_dotfile "${DOTFILES_ROOT}/configs/nvim/init.lua" "$HOME/.config/nvim/init.lua"
