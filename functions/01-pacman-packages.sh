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

# Sync databases AND upgrade in one go. A bare `pacman -S` against stale
# databases 404s on a fresh install, and `pacman -Sy` alone is an
# unsupported partial upgrade.
echo "Refreshing package databases and upgrading the system..."
sudo pacman -Syu --noconfirm

# A single unknown package name makes `pacman -S` abort the WHOLE
# transaction ("target not found"), so nothing on the list would install.
# Resolve every name first (-Sp also resolves provides), install what
# exists, and report the rest instead of failing everything.
available=()
missing=()
for pkg in "${packages[@]}"; do
    if pacman -Sp "$pkg" &> /dev/null; then
        available+=("$pkg")
    else
        missing+=("$pkg")
    fi
done

# rofi 2.x has native Wayland support; fall back to plain rofi if the
# separate rofi-wayland package is not resolvable.
if [[ " ${missing[*]:-} " == *" rofi-wayland "* ]] && pacman -Sp rofi &> /dev/null; then
    echo -e "\033[33m[INFO] rofi-wayland not found in the repos -- installing rofi instead (2.x supports Wayland natively)\033[0m"
    available+=(rofi)
    still_missing=()
    for pkg in "${missing[@]}"; do
        [ "$pkg" = "rofi-wayland" ] || still_missing+=("$pkg")
    done
    missing=("${still_missing[@]}")
fi

if [ "${#available[@]}" -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${available[@]}"
fi

if [ "${#missing[@]}" -gt 0 ]; then
    echo -e "\033[33m[WARN] Not found in any enabled repo, skipped: ${missing[*]}\033[0m"
    echo "!! Fix or remove these in packages/pacman.txt (or enable the repo that provides them)."
fi

echo -e "\033[32m[SUCCESS] pacman packages installed\033[0m"
