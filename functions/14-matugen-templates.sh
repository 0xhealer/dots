#!/usr/bin/env bash
# functions/14-matugen-templates.sh -- module name: "matugen-templates"
#
# UNVERIFIED SINCE THE v5 UPGRADE: this was built and confirmed against
# Noctalia v4's user-templates mechanism (enableUserTheming in
# settings.json, ~/.config/noctalia/templates/ path convention). v5 uses
# settings.toml with an unconfirmed schema -- whether this same
# mechanism exists at all in v5, under what config keys, is unknown.
# Deploys the same files regardless; verify they actually do anything
# post-upgrade rather than assuming.
#
# Noctalia's own theming engine is matugen-compatible internally
# (confirmed: its codebase literally has a "MatugenTemplates" module and
# its TemplateRenderer is described as using "Matugen-compatible
# syntax"). Rofi and Spicetify are not in its built-in template
# registry -- this fills that gap via user-templates rather than a
# separate standalone matugen process.
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

mkdir -p "$HOME/.config/noctalia/templates/colors"

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

write_module_header "Deploying Noctalia user-templates manifest"
copy_dotfile "${DOTFILES_ROOT}/configs/noctalia/user-templates.toml" "$HOME/.config/noctalia/user-templates.toml"

write_module_header "Deploying Rofi config with color import"
copy_dotfile "${DOTFILES_ROOT}/configs/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"

echo "!! UNVERIFIED post-v5-upgrade: confirm ~/.config/noctalia/settings.toml actually has whatever v5's equivalent of enableUserTheming is, and that v5 even reads user-templates.toml from this same path -- both were only confirmed for v4."
echo "!! Spicetify itself is not installed by this step -- it needs Spotify present first (skipped per request, install manually), and the Spicetify CLI on top of that."

