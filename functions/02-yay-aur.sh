#!/usr/bin/env bash
# functions/02-yay-aur.sh -- bootstraps yay if missing, updates existing
# AUR packages, then installs packages/aur.txt one at a time so one
# broken package (vicinae-bin has had intermittent AUR build breakage)
# can't silently abort every step after it.
set -euo pipefail

# Defensive: 02 runs before 03-git.sh in the numbered order, so if the
# shared .gitconfig's core.autocrlf=true (Windows-appropriate, wrong on
# Linux) is already active on this machine, every git clone below --
# yay's own bootstrap clone and every AUR package clone -- would come
# out CRLF-mangled and fail to build. Confirmed real failure mode, not
# theoretical. Override locally before doing anything that clones.
if [ "$(git config --global --get core.autocrlf 2>/dev/null || echo unset)" = "true" ]; then
    echo -e "\033[33m[WARN] core.autocrlf=true detected -- this corrupts AUR package builds on Linux. Overriding to 'input' now.\033[0m"
    git config --global core.autocrlf input
fi

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

write_module_header "Updating existing AUR packages"
# This is what actually updates noctalia-shell if it's already installed
# -- re-listing it in aur.txt below only installs it if MISSING, it does
# not upgrade an existing install. -Sua updates AUR-originated packages
# specifically (devel/-git packages included with --devel).
yay -Sua --noconfirm || echo "!! AUR update pass reported problems -- check output above, continuing anyway"

write_module_header "Installing AUR packages"

AUR_LIST="${DOTFILES_ROOT}/packages/aur.txt"
mapfile -t aur_packages < <(get_package_list "$AUR_LIST")

if [ "${#aur_packages[@]}" -eq 0 ]; then
    echo "No packages listed in ${AUR_LIST}"
    exit 0
fi

failed_packages=()
for pkg in "${aur_packages[@]}"; do
    echo "--- Installing: ${pkg} ---"
    if yay -S --needed --noconfirm "$pkg"; then
        echo -e "\033[32m[SUCCESS] ${pkg}\033[0m"
    else
        echo -e "\033[31m[FAILED] ${pkg} -- continuing with remaining packages\033[0m"
        failed_packages+=("$pkg")
    fi
done

if [ "${#failed_packages[@]}" -gt 0 ]; then
    echo ""
    echo -e "\033[31m!! The following AUR packages failed to install: ${failed_packages[*]}\033[0m"
    echo "!! This step is NOT treated as a fatal failure -- later steps (hyprland, niri, noctalia, assets) will still run."
    echo "!! For vicinae-bin specifically: if it fails, try 'yay -S vicinae' instead (builds from source, slower, historically more reliable)."
fi
