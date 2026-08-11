#!/usr/bin/env bash
# functions/03-git.sh — deploy git config. Module name: "git" (matches
# the Windows 10-git.ps1 module name so `./install.sh git` works on both).
set -euo pipefail

write_module_header "Deploying git config"
copy_dotfile "${DOTFILES_ROOT}/configs/git/.gitconfig" "$HOME/.gitconfig"
