#!/usr/bin/env bash
# functions/07-hyprland.sh -- module name: "hyprland"
# Installs Hyprland if the distro package step could not, then deploys the
# config that matches the installed version (Lua for 0.55+, hyprlang before).
set -euo pipefail

write_module_header "Ensuring Hyprland is installed"
if ! test_command_exists Hyprland; then
    case "$DOTS_FAMILY" in
        arch|fedora)
            pkg_try_install hyprland || echo -e "\033[33m[WARN] hyprland is not available from ${DOTS_DISTRO}'s repos\033[0m" ;;
        debian)
            # Kali/Debian ship it in the main repos; Ubuntu only from 25.10.
            if ! pkg_try_install hyprland && [ "$DOTS_DISTRO" = "ubuntu" ]; then
                echo -e "\033[33m[INFO] hyprland not in this Ubuntu's repos -- trying the community PPA ppa:cppiber/hyprland\033[0m"
                sudo add-apt-repository -y ppa:cppiber/hyprland && sudo apt-get update && pkg_try_install hyprland \
                    || echo -e "\033[33m[WARN] Could not install Hyprland on this Ubuntu release -- see https://wiki.hypr.land/Getting-Started/Installation/\033[0m"
            fi ;;
    esac
fi

write_module_header "Deploying Hyprland config"
HYPR_DIR="$HOME/.config/hypr"
mkdir -p "$HYPR_DIR"
version="$(program_version Hyprland --version)"
[ -n "$version" ] || version="$(program_version hyprctl version)"

if [ -z "$version" ]; then
    echo -e "\033[33m[WARN] Hyprland version unknown (not installed?) -- deploying both hyprland.lua and hyprland.conf; Hyprland uses whichever it understands\033[0m"
    copy_dotfile "${DOTFILES_ROOT}/configs/hypr/hyprland.lua" "$HYPR_DIR/hyprland.lua"
    copy_dotfile "${DOTFILES_ROOT}/configs/hypr/hyprland.conf" "$HYPR_DIR/hyprland.conf"
elif version_ge "$version" "0.55"; then
    echo "Hyprland ${version}: Lua config"
    copy_dotfile "${DOTFILES_ROOT}/configs/hypr/hyprland.lua" "$HYPR_DIR/hyprland.lua"
    # An old hyprland.conf next to the .lua is ignored/confusing -- park it.
    [ -f "$HYPR_DIR/hyprland.conf" ] && mv "$HYPR_DIR/hyprland.conf" "$HYPR_DIR/hyprland.conf.bak"
else
    echo "Hyprland ${version} (< 0.55): hyprlang config"
    copy_dotfile "${DOTFILES_ROOT}/configs/hypr/hyprland.conf" "$HYPR_DIR/hyprland.conf"
fi
