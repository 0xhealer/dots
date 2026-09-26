#!/usr/bin/env bash
# functions/14-matugen-templates.sh -- module name: "matugen-templates"
#
# Fetches the Spicetify (Sleek) template that configs/noctalia/config.toml's
# [theme.templates.user.spicetify] points at. Only useful when Noctalia is
# installed (Arch/CachyOS) -- everything else (kitty, foot, ghostty, rofi,
# hyprland, niri, fish) is themed by configs/theme, see 20-theme.sh.
set -euo pipefail

if ! test_command_exists noctalia; then
    echo -e "\033[33m[SKIP] Noctalia is not installed -- no Noctalia templates needed (rofi & terminals are themed by configs/theme)\033[0m"
    exit 0
fi

write_module_header "Fetching the Spicetify matugen template"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
git clone --depth 1 https://github.com/InioX/matugen-themes.git "${TMP_DIR}/matugen-themes"

# `|| true`: with pipefail, a missing templates/ dir would otherwise abort
# the step before the friendly message below.
SPOTIFY_TEMPLATE="$(find "${TMP_DIR}/matugen-themes" -type f \( -iname '*spicetify*' -o -iname '*sleek*' \) 2>/dev/null | head -n1 || true)"

mkdir -p "$HOME/.config/noctalia/templates"
if [ -n "$SPOTIFY_TEMPLATE" ]; then
    cp "$SPOTIFY_TEMPLATE" "$HOME/.config/noctalia/templates/spicetify.ini"
    echo -e "\033[32m[SUCCESS] Spicetify template copied from $(basename "$SPOTIFY_TEMPLATE")\033[0m"
else
    echo "!! Could not find a spicetify/sleek template under matugen-themes -- check https://github.com/InioX/matugen-themes/tree/main/templates by hand" >&2
fi

echo "!! Spicetify itself only themes Spotify once Spotify is installed (manual install)."
