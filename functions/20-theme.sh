#!/usr/bin/env bash
# functions/20-theme.sh -- module name: "theme"
# Wallpaper-driven theming. Deploys configs/theme to ~/.config/theme and
# renders the palette into every app's colour file:
#
#   ~/.config/theme/theme.conf          the palette (source of truth)
#   ~/.config/theme/generated/*         kitty, foot, ghostty, rofi, hyprland, niri, fish
#
# Change the theme any time with:  theme-apply <image> | --random | --pick
# (Mod+W / Mod+Shift+W in both compositors). Runs LAST so every app config
# it feeds is already in place.
set -euo pipefail

THEME_SRC="${DOTFILES_ROOT}/configs/theme"
THEME_DEST="$HOME/.config/theme"

write_module_header "Deploying theme engine"
mkdir -p "$THEME_DEST/templates" "$THEME_DEST/generated" "$HOME/.local/bin"
cp "${THEME_SRC}/palette.py" "${THEME_SRC}/theme-apply" "$THEME_DEST/"
cp "${THEME_SRC}"/templates/*.tpl "$THEME_DEST/templates/"
chmod +x "$THEME_DEST/palette.py" "$THEME_DEST/theme-apply"
ln -sf "$THEME_DEST/theme-apply" "$HOME/.local/bin/theme-apply"

# Keep the palette of whatever wallpaper is already applied on this machine;
# only a fresh machine gets the default one shipped in the repo.
if [ -f "$THEME_DEST/theme.conf" ]; then
    echo "Keeping existing ${THEME_DEST}/theme.conf"
else
    sed "s|@HOME@|${HOME}|g" "${THEME_SRC}/theme.conf" > "$THEME_DEST/theme.conf"
    echo -e "\033[32m[SUCCESS] Installed default palette\033[0m"
fi

if ! python3 -c 'import PIL' 2> /dev/null; then
    echo -e "\033[33m[WARN] python Pillow missing -- theme-apply <image> can't read wallpapers until it's installed (packages/linux.txt: pillow). Rendering the existing palette still works.\033[0m"
fi

write_module_header "Rendering palette into app configs"
"$THEME_DEST/theme-apply" --render
ls "$THEME_DEST/generated"

# On a live Wayland session also (re)set the wallpaper right now.
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    "$THEME_DEST/theme-apply" --restore || true
fi

if test_command_exists niri; then
    niri validate --config "$HOME/.config/niri/config.kdl" \
        || echo "!! niri validate reported problems -- check output above before logging into a Niri session"
fi

echo -e "\033[32m[SUCCESS] Theme ready. Change it with: theme-apply --pick\033[0m"
