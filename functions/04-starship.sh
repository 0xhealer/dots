#!/usr/bin/env bash
# functions/04-starship.sh — module name: "starship" (shared name with
# the Windows 06-starship.ps1 module).
set -euo pipefail

write_module_header "Deploying starship config"
mkdir -p "$HOME/.config"
copy_dotfile "${DOTFILES_ROOT}/configs/starship/starship.toml" "$HOME/.config/starship.toml"

SHELL_RC="$HOME/.bashrc"
if ! grep -q 'starship init bash' "$SHELL_RC" 2>/dev/null; then
    echo 'eval "$(starship init bash)"' >> "$SHELL_RC"
    echo -e "\033[32m[SUCCESS] Added starship init to ${SHELL_RC}\033[0m"
fi
