#!/usr/bin/env bash
# functions/12-sddm-theme.sh -- module name: "sddm-theme"
# Installs the official Catppuccin SDDM theme (Mocha flavor) to match
# the rest of the setup. Source: https://github.com/catppuccin/sddm
set -euo pipefail

write_module_header "Installing SDDM theme dependencies"
sudo pacman -S --needed --noconfirm qt6-svg qt6-declarative unzip

write_module_header "Downloading Catppuccin SDDM theme (Mocha, Mauve accent)"
TMP_DIR="$(mktemp -d)"
# Confirmed against the actual release asset list on GitHub (catppuccin/sddm
# releases page) -- the real filename pattern is
# catppuccin-<flavor>-<accent>-sddm.zip (e.g. catppuccin-frappe-mauve-sddm.zip
# was visible in the v1.1.2 release). The previous URL
# (catppuccin-mocha-mauve.zip) was missing the "-sddm" segment, hence the 404.
curl -fsSL -o "${TMP_DIR}/catppuccin-sddm.zip" \
    "https://github.com/catppuccin/sddm/releases/latest/download/catppuccin-mocha-mauve-sddm.zip" \
    || { echo "!! Download failed -- check https://github.com/catppuccin/sddm/releases for the exact current asset name and adjust the URL above if this 404s" >&2; exit 1; }

sudo mkdir -p /usr/share/sddm/themes
sudo unzip -o "${TMP_DIR}/catppuccin-sddm.zip" -d /usr/share/sddm/themes/
rm -rf "$TMP_DIR"

write_module_header "Configuring SDDM to use the theme"
# Discover the actual installed theme folder name rather than guessing
# it (accent variants like catppuccin-mocha-mauve are a real
# possibility per the AUR package listings, and I don't have a
# confirmed exact folder name from a real install to hardcode).
THEME_DIR="$(find /usr/share/sddm/themes -maxdepth 1 -iname 'catppuccin-mocha*' -type d | head -n1)"
if [ -z "$THEME_DIR" ]; then
    echo "!! Could not find an installed catppuccin-mocha* theme folder under /usr/share/sddm/themes -- check what the zip actually extracted (unzip -l) and set /etc/sddm.conf.d/catppuccin.conf's Current= by hand" >&2
    exit 1
fi
THEME_NAME="$(basename "$THEME_DIR")"

sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/catppuccin.conf > /dev/null << SDDMCONF
[Theme]
Current=${THEME_NAME}
SDDMCONF

echo -e "\033[32m[SUCCESS] SDDM theme set to ${THEME_NAME}\033[0m"
echo "!! Takes effect on next login-manager restart (or reboot) -- theme.conf inside ${THEME_DIR} can be edited further for font/background if needed"
