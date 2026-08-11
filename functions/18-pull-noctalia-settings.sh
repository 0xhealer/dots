#!/usr/bin/env bash
# functions/18-pull-noctalia-settings.sh -- module name:
# "pull-noctalia-settings"
#
# NOT part of a normal ./install.sh run -- this is a one-off, run
# manually whenever you've changed Noctalia's settings through its own
# GUI and want those changes captured back into the dotfiles repo.
#
# install.sh only ever copies repo -> live system (copy_dotfile). There
# is no automatic reverse sync -- if you edit settings via the GUI and
# never run this, the next `./install.sh noctalia` will silently
# overwrite your live changes with whatever's still in the repo. This
# script is the deliberate, explicit way to go the other direction.
set -euo pipefail

LIVE_FILE="$HOME/.config/noctalia/settings.toml"
REPO_FILE="${DOTFILES_ROOT}/configs/noctalia/settings.toml"

if [ ! -f "$LIVE_FILE" ]; then
    echo "No live settings.toml found at ${LIVE_FILE} -- nothing to pull" >&2
    exit 1
fi

write_module_header "Pulling live Noctalia settings into the repo"
diff -u "$REPO_FILE" "$LIVE_FILE" || true
echo ""
read -rp "Copy the live file over the repo's version shown above? [y/N]: " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    cp "$LIVE_FILE" "$REPO_FILE"
    echo -e "\033[32m[SUCCESS] Repo file updated -- review with 'git diff', then commit and push yourself\033[0m"
else
    echo "Cancelled -- repo file left unchanged"
fi
