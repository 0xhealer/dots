#!/usr/bin/env bash
# functions/06-fastfetch.sh -- module name: "fastfetch"
# Logo is now the image at assets/fastfetch/logo.png, deployed by
# functions/10-assets.sh (module name "assets") -- run both. The old
# ascii eagle-logo.txt is no longer referenced by config.jsonc, kept in
# the repo only in case you want to revert to it.
set -euo pipefail

write_module_header "Deploying fastfetch config"
copy_dotfile "${DOTFILES_ROOT}/configs/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

if [ ! -f "$HOME/.config/fastfetch/logo.png" ]; then
    echo "!! config.jsonc points at ~/.config/fastfetch/logo.png which isn't deployed yet -- run functions/10-assets.sh (module 'assets') too, or fastfetch will error/fall back"
fi
