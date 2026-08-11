#!/usr/bin/env bash
# functions/09-noctalia.sh -- module name: "noctalia"
# Installs Noctalia v5 (upgraded from v4 per request) and deploys the
# confirmed-safe subset of settings.toml. v5 is 5.0.0_beta.7 -- genuinely
# beta, and only moved from AUR into Arch's own extra-testing repo about
# a day before this was written.
set -euo pipefail

write_module_header "Installing Noctalia v5"
if pacman -Si noctalia &> /dev/null; then
    sudo pacman -S --needed --noconfirm noctalia
    echo -e "\033[32m[SUCCESS] noctalia installed from pacman (extra-testing)\033[0m"
elif command -v yay &> /dev/null; then
    echo -e "\033[33m[INFO] noctalia not visible in pacman's repos (extra-testing likely not enabled) -- falling back to AUR\033[0m"
    yay -S --needed --noconfirm noctalia
else
    echo "Can't install noctalia: not in pacman's visible repos and yay isn't available yet -- run functions/02-yay-aur.sh first" >&2
    exit 1
fi

write_module_header "Deploying Noctalia settings (confirmed subset only)"
mkdir -p "$HOME/.config/noctalia"
copy_dotfile "${DOTFILES_ROOT}/configs/noctalia/settings.toml" "$HOME/.config/noctalia/settings.toml"

echo ""
echo "!! settings.toml only sets fields I could confirm from real sources"
echo "!! (theme, wallpaper). Opacity/blur/template-activation keys for"
echo "!! v5 beta.7 specifically are NOT in this file -- guessing TOML"
echo "!! schema on fast-moving beta software is exactly what caused the"
echo "!! v4 troubleshooting loop. Instead:"
echo "!!   1. Open Noctalia's Settings GUI, set opacity/blur there directly"
echo "!!   2. Run functions/18-pull-noctalia-settings.sh to copy the"
echo "!!      live file back into this repo so it's captured for next time"
