#!/usr/bin/env bash
# functions/05-nvim.sh — module name: "nvim"
# Deploys the WHOLE config tree (init.lua, lua/, after/, nvim-pack-lock.json).
# Copying init.lua alone left every require("core.*") / require("plugins.*")
# unresolved.
set -euo pipefail

write_module_header "Deploying nvim config"

NVIM_SRC="${DOTFILES_ROOT}/configs/nvim"
NVIM_DEST="$HOME/.config/nvim"

if [ ! -d "$NVIM_SRC" ]; then
    echo "Neovim configuration directory not found: ${NVIM_SRC}" >&2
    exit 1
fi

if [ -d "$NVIM_DEST" ]; then
    backup_dir="$(new_backup_directory nvim)"
    backup_item "$NVIM_DEST" "${backup_dir}/nvim-$(date +%H%M%S)"
    rm -rf "$NVIM_DEST"
fi

mkdir -p "$NVIM_DEST"
cp -r "${NVIM_SRC}/." "$NVIM_DEST/"
echo -e "\033[32m[SUCCESS] Deployed: ${NVIM_DEST}\033[0m"
echo "[INFO] Launch nvim once to bootstrap plugins."
