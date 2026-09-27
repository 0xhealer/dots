#!/usr/bin/env bash
# functions/11-fish.sh -- module name: "fish"
# Deploys fish config (with starship wired in) and sets fish as the
# default login shell, per request ("fish throughout").
set -euo pipefail

write_module_header "Deploying fish config"
copy_dotfile "${DOTFILES_ROOT}/configs/shell/config.fish" "$HOME/.config/fish/config.fish"

# Everything config.fish sources lives under ~/.config/fish/dots/ --
# deliberately NOT ~/.config/fish/functions/, whose autoload semantics
# (lazy, one file per function) don't fit this profile's up-front,
# dependency-ordered loading (see the comment at the top of config.fish).
DOTS_FISH_DIR="$HOME/.config/fish/dots"
mkdir -p "$DOTS_FISH_DIR/functions"
for f in aliases.fish fzf.fish keybinds.fish prompt.fish; do
    copy_dotfile "${DOTFILES_ROOT}/configs/shell/$f" "$DOTS_FISH_DIR/$f"
done
for f in "${DOTFILES_ROOT}"/configs/shell/functions/*.fish; do
    copy_dotfile "$f" "$DOTS_FISH_DIR/functions/$(basename "$f")"
done

write_module_header "Setting fish as default shell"
# `|| true`: under errexit a failing `command -v` would kill the step
# before the friendly message below could print.
FISH_PATH="$(command -v fish || true)"
if [ -z "$FISH_PATH" ]; then
    echo "fish not found on PATH -- is it in packages/linux.txt and installed?" >&2
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
