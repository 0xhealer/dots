#!/usr/bin/env bash
# functions/13-limine-theme.sh -- module name: "limine-theme"
# Patches ONLY the color keys in /boot/limine.conf to the wallpaper
# palette (configs/theme) -- does not touch kernel entries, timeout, default
# boot target, or anything else CachyOS manages in that file.
#
# /boot/limine.conf is bootloader-critical. This backs the file up
# before touching it and only ever replaces/appends the specific color
# keys below -- never a wholesale overwrite. Still: this is not a place
# to skip a VM snapshot before running, if you have one available.
set -euo pipefail

write_module_header "Locating limine.conf"
# sudo: the ESP is typically mounted with a root-only umask, so a plain
# `find` as the normal user cannot even traverse /boot and would wrongly
# report "not found".
LIMINE_CONF="$(sudo find /boot -maxdepth 3 -type f -name 'limine.conf' 2>/dev/null | head -n1 || true)"
if [ -z "$LIMINE_CONF" ]; then
    echo -e "\033[33m[SKIP] limine.conf not found under /boot -- this machine doesn't use Limine, nothing to theme\033[0m"
    exit 0
fi
echo "Found: ${LIMINE_CONF}"

write_module_header "Backing up limine.conf"
BACKUP="${LIMINE_CONF}.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp "$LIMINE_CONF" "$BACKUP"
echo -e "\033[32m[SUCCESS] Backed up to ${BACKUP} -- restore with: sudo cp ${BACKUP} ${LIMINE_CONF}\033[0m"

write_module_header "Applying wallpaper-theme color keys"
# Colours come from the same palette as every other config
# (configs/theme -> ~/.config/theme/theme.conf). Re-run this step after
# changing the wallpaper to update the boot menu too.
# interface_branding_color / interface_help_color(_bright) are confirmed
# valid limine.conf keys per catppuccin/limine's own README.
THEME_CONF="$HOME/.config/theme/theme.conf"
[ -f "$THEME_CONF" ] || THEME_CONF="${DOTFILES_ROOT}/configs/theme/theme.conf"
tc() {  # theme colour without the leading '#'
    sed -n "s/^$1 *= *#\{0,1\}//p" "$THEME_CONF" | head -n1
}
declare -A COLOR_KEYS=(
    [term_palette]="$(tc black);$(tc red);$(tc green);$(tc yellow);$(tc blue);$(tc magenta);$(tc cyan);$(tc white)"
    [term_palette_bright]="$(tc bright_black);$(tc bright_red);$(tc bright_green);$(tc bright_yellow);$(tc bright_blue);$(tc bright_magenta);$(tc bright_cyan);$(tc bright_white)"
    [term_foreground]="$(tc fg)"
    [interface_branding_color]="$(tc primary)"
    [interface_help_color]="$(tc fg_dim)"
    [interface_help_color_bright]="$(tc fg)"
)
# NOTE: deliberately NOT setting term_background here -- the one
# reference I found for it used a value ("ffffffff") that looks
# inconsistent with a dark Mocha background and I could not confirm it
# independently. Leaving Limine's own default rather than shipping a
# color I'm not confident is right; add it yourself once you've
# confirmed the correct value if you want the terminal background
# explicitly set too.

# Work on a private copy, then copy it back over the original (cp onto an
# existing file keeps its owner/mode). Reading needs sudo too -- the file
# is root-only, so an unprivileged `grep` would treat it as empty and
# append duplicate keys on every run.
#
# Global options MUST come before the first boot entry ("/Name" lines): a
# `key: value` line appended at the end of the file is parsed as part of
# the LAST entry, not as a global setting, so the theme would never apply.
WORK_COPY="$(mktemp)"
trap 'rm -f "$WORK_COPY" "${WORK_COPY}.new"' EXIT
# shellcheck disable=SC2024  # intentional: WORK_COPY is a user-owned temp file
sudo cat "$LIMINE_CONF" > "$WORK_COPY"

for key in "${!COLOR_KEYS[@]}"; do
    value="${COLOR_KEYS[$key]}"
    if grep -qE "^${key}:" "$WORK_COPY"; then
        sed -i "s|^${key}:.*|${key}: ${value}|" "$WORK_COPY"
    elif grep -qm1 '^/' "$WORK_COPY"; then
        awk -v line="${key}: ${value}" '!done && /^\// { print line; done=1 } { print }' "$WORK_COPY" > "${WORK_COPY}.new"
        mv "${WORK_COPY}.new" "$WORK_COPY"
    else
        echo "${key}: ${value}" >> "$WORK_COPY"
    fi
done

sudo cp "$WORK_COPY" "$LIMINE_CONF"

echo -e "\033[32m[SUCCESS] Color keys applied\033[0m"
echo "!! Changes to limine.conf take effect on next boot, no command needed -- but VERIFY the file looks right (cat ${LIMINE_CONF}) before rebooting, and keep the backup path above handy"
