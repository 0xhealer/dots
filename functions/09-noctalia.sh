#!/usr/bin/env bash
# functions/09-noctalia.sh -- module name: "noctalia"
# Installs Noctalia v5 and deploys config.toml -- CORRECT filename,
# confirmed from the official example.toml's own instructions ("Copy to
# ~/.config/noctalia/config.toml"). Earlier settings.toml/settings.json
# names were both wrong for v5.
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

write_module_header "Deploying Noctalia config"
mkdir -p "$HOME/.config/noctalia"
copy_dotfile "${DOTFILES_ROOT}/configs/noctalia/config.toml" "$HOME/.config/noctalia/config.toml"

echo ""
echo "!! theme.templates.builtin_ids (kitty, niri, gtk3, gtk4, qt) is a"
echo "!! best guess carried over from v4's confirmed ids -- run"
echo "!! 'noctalia theme --list-templates' on the live system to confirm"
echo "!! v5 uses the same spelling before trusting it fully."
echo "!! GUI-made changes go to ~/.local/state/noctalia/settings.toml,"
echo "!! a DIFFERENT file -- functions/18-pull-noctalia-settings.sh reads"
echo "!! from there, not from this config.toml."
