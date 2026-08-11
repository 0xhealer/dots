#!/usr/bin/env bash
# functions/09-noctalia.sh -- module name: "noctalia"
# Deploys Noctalia's shared settings for both the Hyprland and Niri legs.
set -euo pipefail

write_module_header "Deploying Noctalia config"
copy_dotfile "${DOTFILES_ROOT}/configs/noctalia/settings.json" "$HOME/.config/noctalia/settings.json"

echo "!! configs/noctalia/settings.json format is UNVERIFIED -- v4 vs v5 use different config formats entirely. Run 'noctalia-shell --version' and check docs.noctalia.dev before trusting this file was even the right one to deploy"
