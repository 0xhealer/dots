#!/usr/bin/env bash
# functions/02-yay-aur.sh — bootstraps yay if missing, then installs
# packages/aur.txt (currently just noctalia-shell).
set -euo pipefail

write_module_header "Verify yay"

if ! test_command_exists yay; then
    echo -e "\033[33m[INFO] yay not found. Building from AUR...\033[0m"
    TMP_YAY="$(mktemp -d)"
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git "$TMP_YAY/yay"
    (cd "$TMP_YAY/yay" && makepkg -si --noconfirm)
    rm -rf "$TMP_YAY"

    if ! test_command_exists yay; then
        echo "yay installation failed" >&2
        exit 1
    fi
    echo -e "\033[32m[SUCCESS] yay installed\033[0m"
else
    echo -e "\033[32m[SUCCESS] yay detected\033[0m"
fi

write_module_header "Installing AUR packages"

AUR_LIST="${DOTFILES_ROOT}/packages/aur.txt"
mapfile -t aur_packages < <(get_package_list "$AUR_LIST")

if [ "${#aur_packages[@]}" -eq 0 ]; then
    echo "No packages listed in ${AUR_LIST}"
    exit 0
fi

yay -S --needed --noconfirm "${aur_packages[@]}"
echo -e "\033[32m[SUCCESS] AUR packages installed\033[0m"
