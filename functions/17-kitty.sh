#!/usr/bin/env bash
# functions/17-kitty.sh -- module name: "kitty"
# Was never actually being deployed anywhere despite existing in
# configs/terminal/kitty.conf and being referenced by both compositor
# configs' Mod+T/Mod+Return binds -- real gap, not a redesign.
set -euo pipefail

write_module_header "Deploying kitty config"
copy_dotfile "${DOTFILES_ROOT}/configs/terminal/kitty.conf" "$HOME/.config/kitty/kitty.conf"
