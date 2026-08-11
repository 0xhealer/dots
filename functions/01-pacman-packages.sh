#!/usr/bin/env bash
# functions/01-pacman-packages.sh — installs packages/pacman.txt
set -euo pipefail

write_module_header "Installing pacman packages"

PACMAN_LIST="${DOTFILES_ROOT}/packages/pacman.txt"
mapfile -t packages < <(get_package_list "$PACMAN_LIST")

if [ "${#packages[@]}" -eq 0 ]; then
    echo "No packages listed in ${PACMAN_LIST}"
    exit 0
fi

sudo pacman -S --needed --noconfirm "${packages[@]}"
echo -e "\033[32m[SUCCESS] pacman packages installed\033[0m"
