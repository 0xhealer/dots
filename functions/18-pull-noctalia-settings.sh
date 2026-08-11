#!/usr/bin/env bash
# functions/18-pull-noctalia-settings.sh -- module name:
# "pull-noctalia-settings"
#
# NOT part of a normal ./install.sh run -- this is a one-off, run
# manually whenever you've changed Noctalia's settings through its own
# GUI and want to consider bringing those changes into the repo.
#
# IMPORTANT, and different from how this script worked before the v5
# filename fix: the GUI does NOT write to config.toml. It writes to
# ~/.local/state/noctalia/settings.toml, which contains ONLY the deltas
# from config.toml (confirmed from Noctalia's own config-system docs --
# if a GUI value matches what config.toml already says, the key gets
# REMOVED from settings.toml rather than stored as a redundant
# override). That means this file is a partial diff, not a full config
# -- copying it wholesale over config.toml would delete every setting
# the GUI didn't touch. This script shows you the file's contents
# instead of blindly overwriting anything; you decide what to
# hand-merge into config.toml.
set -euo pipefail

STATE_FILE="$HOME/.local/state/noctalia/settings.toml"

if [ ! -f "$STATE_FILE" ]; then
    echo "No GUI-override file found at ${STATE_FILE} yet -- normal on a first install before Noctalia's been run/Settings opened, nothing to show"
    exit 0
fi

write_module_header "GUI-made changes (deltas from config.toml)"
cat "$STATE_FILE"
echo ""
echo "These are overrides ON TOP OF configs/noctalia/config.toml, not a"
echo "full config. Manually copy whichever keys above you want to make"
echo "permanent into configs/noctalia/config.toml, then re-run"
echo "'./install.sh noctalia' to redeploy -- that keeps config.toml as"
echo "the single readable source of truth instead of scattering settings"
echo "across two files."
