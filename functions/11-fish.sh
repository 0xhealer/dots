#!/usr/bin/env bash
# functions/11-fish.sh -- module name: "fish"
# Deploys fish config (with starship wired in) and sets fish as the
# default login shell, per request ("fish throughout").
set -euo pipefail

write_module_header "Deploying fish config"
copy_dotfile "${DOTFILES_ROOT}/configs/shell/config.fish" "$HOME/.config/fish/config.fish"

write_module_header "Setting fish as default shell"
FISH_PATH="$(command -v fish)"
if [ -z "$FISH_PATH" ]; then
    echo "fish not found on PATH -- is it in packages/pacman.txt and installed?" >&2
    exit 1
fi

if ! grep -qxF "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    echo -e "\033[32m[SUCCESS] Added ${FISH_PATH} to /etc/shells\033[0m"
fi

if [ "$SHELL" != "$FISH_PATH" ]; then
    sudo chsh -s "$FISH_PATH" "$USER"
    echo -e "\033[32m[SUCCESS] Default shell set to fish -- takes effect on next login\033[0m"
else
    echo -e "\033[32m[SUCCESS] fish already the default shell\033[0m"
fi
