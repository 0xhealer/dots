#!/usr/bin/env bash
# functions/06-fastfetch.sh -- module name: "fastfetch"
# config.jsonc uses "logo": {"type": "none"} (no image / ASCII logo), so
# there is nothing else to deploy besides the config itself.
set -euo pipefail

write_module_header "Deploying fastfetch config"
copy_dotfile "${DOTFILES_ROOT}/configs/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
