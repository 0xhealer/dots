#!/usr/bin/env bash
# functions/13-limine-theme.sh -- module name: "limine-theme"
# Patches ONLY the color keys in /boot/limine.conf to a Catppuccin
# Mocha palette -- does not touch kernel entries, timeout, default
# boot target, or anything else CachyOS manages in that file.
#
# /boot/limine.conf is bootloader-critical. This backs the file up
# before touching it and only ever replaces/appends the specific color
# keys below -- never a wholesale overwrite. Still: this is not a place
# to skip a VM snapshot before running, if you have one available.
set -euo pipefail

write_module_header "Locating limine.conf"
LIMINE_CONF="$(find /boot -maxdepth 3 -type f -name 'limine.conf' 2>/dev/null | head -n1)"
if [ -z "$LIMINE_CONF" ]; then
    echo "limine.conf not found under /boot -- is this box actually using Limine?" >&2
    exit 1
fi
echo "Found: ${LIMINE_CONF}"

write_module_header "Backing up limine.conf"
BACKUP="${LIMINE_CONF}.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp "$LIMINE_CONF" "$BACKUP"
echo -e "\033[32m[SUCCESS] Backed up to ${BACKUP} -- restore with: sudo cp ${BACKUP} ${LIMINE_CONF}\033[0m"

write_module_header "Applying Catppuccin Mocha color keys"
# term_palette / term_palette_bright are the standard Catppuccin Mocha
# ANSI 16-color mapping -- these hex values are the well-known official
# Catppuccin Mocha palette, confirmed independent of any single source.
# interface_branding_color / interface_help_color(_bright) are
# confirmed valid limine.conf keys per catppuccin/limine's own README.
declare -A COLOR_KEYS=(
    [term_palette]="1e1e2e;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4"
    [term_palette_bright]="585b70;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4"
    [term_foreground]="cdd6f4"
    [interface_branding_color]="cdd6f4"
    [interface_help_color]="a6adc8"
    [interface_help_color_bright]="cdd6f4"
)
# NOTE: deliberately NOT setting term_background here -- the one
# reference I found for it used a value ("ffffffff") that looks
# inconsistent with a dark Mocha background and I could not confirm it
# independently. Leaving Limine's own default rather than shipping a
# color I'm not confident is right; add it yourself once you've
# confirmed the correct value if you want the terminal background
# explicitly set too.

for key in "${!COLOR_KEYS[@]}"; do
    value="${COLOR_KEYS[$key]}"
    if grep -qE "^${key}:" "$LIMINE_CONF"; then
        sudo sed -i "s|^${key}:.*|${key}: ${value}|" "$LIMINE_CONF"
    else
        echo "${key}: ${value}" | sudo tee -a "$LIMINE_CONF" > /dev/null
    fi
done

echo -e "\033[32m[SUCCESS] Color keys applied\033[0m"
echo "!! Changes to limine.conf take effect on next boot, no command needed -- but VERIFY the file looks right (cat ${LIMINE_CONF}) before rebooting, and keep the backup path above handy"
