#!/usr/bin/env bash
# functions/15-fonts.sh -- module name: "fonts"
# Installs the Nerd Fonts already sitting in fonts/ (AnonymousPro,
# FiraCode, Hack) -- these mirror packages/scoop.txt's AnonymousPro-NF,
# FiraCode-NF, Hack-NF entries but were never actually deployed on the
# Linux leg despite being in the shared repo tree the whole time.
set -euo pipefail

write_module_header "Installing Nerd Fonts"

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

for zip in "${DOTFILES_ROOT}"/fonts/*.zip; do
    name="$(basename "$zip" .zip)"
    echo "Extracting ${name}..."
    unzip -oq "$zip" -d "${FONT_DIR}/${name}"
done

echo -e "\033[32m[SUCCESS] Fonts extracted to ${FONT_DIR}\033[0m"

write_module_header "Rebuilding font cache"
fc-cache -f "$FONT_DIR"
echo -e "\033[32m[SUCCESS] Font cache rebuilt\033[0m"
