#!/usr/bin/env bash
# functions/01-packages.sh — installs packages/linux.txt for whichever
# distro this is (pacman / apt / dnf). Module name: "packages".
set -euo pipefail

write_module_header "Installing packages for ${DOTS_DISTRO}"

echo "Refreshing package databases and upgrading the system..."
pkg_refresh

available=()
missing=()
while read -r _group name cell; do
    if pkg="$(resolve_cell "$cell")"; then
        available+=("$pkg")
    else
        missing+=("${name}(${cell})")
    fi
done < <(linux_package_cells)

if [ "${#available[@]}" -gt 0 ]; then
    # One transaction is fastest; if it fails on some odd package, retry one
    # by one so a single bad package can't block everything else.
    if ! pkg_install "${available[@]}"; then
        echo -e "\033[33m[WARN] Batch install failed -- retrying package by package\033[0m"
        failed=()
        for pkg in "${available[@]}"; do
            pkg_install "$pkg" || failed+=("$pkg")
        done
        if [ "${#failed[@]}" -gt 0 ]; then
            echo -e "\033[33m[WARN] Could not install: ${failed[*]}\033[0m"
        fi
    fi
fi

if [ "${#missing[@]}" -gt 0 ]; then
    echo -e "\033[33m[INFO] Not in ${DOTS_DISTRO}'s enabled repos (skipped or handled by later steps):\033[0m"
    printf '    %s\n' "${missing[@]}"
fi

# Kali: optional big metapackages (multi-GB). Off unless asked for.
if [ "$DOTS_DISTRO" = "kali" ] && [ "${DOTS_KALI_META:-0}" = "1" ]; then
    write_module_header "Installing Kali tool metapackages"
    pkg_install kali-tools-top10 kali-tools-web kali-tools-passwords kali-tools-reverse-engineering || true
fi

# Debian/Ubuntu install fd as "fdfind" and bat as "batcat" -- link the names
# the rest of this setup (and the aliases) expect.
if is_debian; then
    mkdir -p "$HOME/.local/bin"
    command -v fdfind > /dev/null && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    command -v batcat > /dev/null && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

echo -e "\033[32m[SUCCESS] packages installed\033[0m"
