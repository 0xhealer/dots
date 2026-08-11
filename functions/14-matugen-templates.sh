#!/usr/bin/env bash
# functions/14-matugen-templates.sh -- module name: "matugen-templates"
#
# NOW CONFIRMED for v5: user templates are declared directly in
# config.toml under [theme.templates.user.<name>] (confirmed from
# Noctalia's official example.toml) -- functions/09-noctalia.sh already
# deploys that. This step only fetches the actual template FILE
# CONTENT that config.toml's input_path entries point at.
#
# Noctalia's own theming engine is matugen-compatible internally
# (confirmed: real commits like "Matugen: move templates a folder up"
# and a "MatugenTemplates" module in its own codebase). Rofi and
# Spicetify aren't in its built-in template registry -- this fills that
# gap via user templates rather than a separate standalone matugen
# process.
set -euo pipefail

write_module_header "Fetching real matugen templates (rofi, spicetify)"
# The exact filenames inside InioX/matugen-themes weren't confirmed
# against a real directory listing -- cloning and discovering rather
# than guessing a raw.githubusercontent.com URL and risking a 404 like
# the SDDM theme download did earlier.
TMP_DIR="$(mktemp -d)"
git clone --depth 1 https://github.com/InioX/matugen-themes.git "${TMP_DIR}/matugen-themes"

ROFI_TEMPLATE="$(find "${TMP_DIR}/matugen-themes/templates" -iname '*rofi*' -type f | head -n1)"
SPOTIFY_TEMPLATE="$(find "${TMP_DIR}/matugen-themes/templates" -iname '*spicetify*' -o -iname '*sleek*' -type f 2>/dev/null | head -n1)"

# Paths match config.toml's [theme.templates.user.*].input_path entries exactly.
mkdir -p "$HOME/.config/noctalia/templates"

if [ -n "$ROFI_TEMPLATE" ]; then
    cp "$ROFI_TEMPLATE" "$HOME/.config/noctalia/templates/rofi.rasi"
    echo -e "\033[32m[SUCCESS] Rofi template copied from $(basename "$ROFI_TEMPLATE")\033[0m"
else
    echo "!! Could not find a rofi template under matugen-themes/templates -- check https://github.com/InioX/matugen-themes/tree/main/templates by hand" >&2
fi

if [ -n "$SPOTIFY_TEMPLATE" ]; then
    cp "$SPOTIFY_TEMPLATE" "$HOME/.config/noctalia/templates/spicetify.ini"
    echo -e "\033[32m[SUCCESS] Spicetify template copied from $(basename "$SPOTIFY_TEMPLATE")\033[0m"
else
    echo "!! Could not find a spicetify/sleek template under matugen-themes/templates -- check https://github.com/InioX/matugen-themes/tree/main/templates by hand" >&2
fi

rm -rf "$TMP_DIR"

write_module_header "Deploying Rofi config with color import"
copy_dotfile "${DOTFILES_ROOT}/configs/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"

echo "!! Spicetify itself is not installed by this step, only its CLI package (spicetify-cli, see pacman.txt) -- it still needs Spotify present first (skipped per request, install manually) before the theme actually applies to anything."
