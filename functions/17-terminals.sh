#!/usr/bin/env bash
# functions/17-terminals.sh -- module name: "terminals"
# Deploys the kitty, foot and ghostty configs, and the small launcher
# scripts (dots-term, dots-browser) the compositor binds call.
# Colours are not in these files: each one includes a file generated from
# the wallpaper palette (see 20-theme.sh / configs/theme).
set -euo pipefail

write_module_header "Deploying terminal configs (kitty, foot, ghostty)"
copy_dotfile_home "${DOTFILES_ROOT}/configs/terminal/kitty.conf"   "$HOME/.config/kitty/kitty.conf"
copy_dotfile_home "${DOTFILES_ROOT}/configs/terminal/foot.ini"     "$HOME/.config/foot/foot.ini"
copy_dotfile      "${DOTFILES_ROOT}/configs/terminal/ghostty.conf" "$HOME/.config/ghostty/config"

for t in kitty foot ghostty; do
    test_command_exists "$t" || echo -e "\033[33m[WARN] ${t} is not installed on ${DOTS_DISTRO} -- config deployed anyway (dots-term falls back to whichever terminal exists)\033[0m"
done

write_module_header "Deploying launcher scripts to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
for script in "${DOTFILES_ROOT}"/configs/bin/*; do
    install -m755 "$script" "$HOME/.local/bin/$(basename "$script")"
    echo -e "\033[32m[SUCCESS] Installed: ~/.local/bin/$(basename "$script")\033[0m"
done

write_module_header "Deploying Rofi config"
copy_dotfile_home "${DOTFILES_ROOT}/configs/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
