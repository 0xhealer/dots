#!/usr/bin/env bash
# functions/08-niri.sh -- module name: "niri"
set -euo pipefail

write_module_header "Deploying Niri config"
copy_dotfile "${DOTFILES_ROOT}/configs/niri/config.kdl" "$HOME/.config/niri/config.kdl"

if test_command_exists niri; then
    niri validate --config "$HOME/.config/niri/config.kdl" || echo "!! niri validate reported problems -- check output above before logging into a Niri session with this config"
fi
