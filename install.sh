#!/usr/bin/env bash
# install.sh -- Linux entrypoint. Mirrors install.ps1's contract:
# discovers functions/*.sh sorted by name, optionally filtered by name
# with the numeric prefix stripped (so "./install.sh starship git" works
# the same way "-Modules starship,git" does on Windows).
#
# Deliberate difference from install.ps1: this does NOT elevate the
# whole script to root. Individual functions/*.sh steps sudo only the
# commands that need it (pacman, yay bootstrap). Running dotfile deploys
# as root would leave root-owned files in $HOME.
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT

COMMON_HELPERS="${DOTFILES_ROOT}/helpers/common.sh"
if [ ! -f "$COMMON_HELPERS" ]; then
    echo "helpers/common.sh not found." >&2
    exit 1
fi
# shellcheck source=helpers/common.sh
source "$COMMON_HELPERS"

# -----------------------------------------------------------------------
# Sudo, entered once
# -----------------------------------------------------------------------
# Individual steps (pacman, yay bootstrap) call sudo separately. Without
# this, sudo's cached-credential timeout can lapse between steps --
# especially around 02-yay-aur.sh, which can take a while building from
# source -- and you get prompted again mid-run. Prime the cache once up
# front and keep it alive in the background for the life of this script.
echo "This installer needs sudo for package installation -- enter your password once:"
sudo -v

sudo_keepalive() {
    # set -e is inherited from install.sh into this backgrounded
    # subshell. Without the "|| true", the FIRST transient failure of
    # `sudo -n true` (a scheduling delay, cache lapsing by a second
    # before the refresh lands) kills this loop permanently under
    # errexit -- not just that iteration, the whole background process
    # exits and every sudo call after that re-prompts from cold. This
    # was the actual cause of repeated password prompts, not a timing
    # gap in the refresh interval.
    while true; do
        sudo -n true 2>/dev/null || true
        sleep 60
    done
}
sudo_keepalive &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

FUNCTIONS_DIR="${DOTFILES_ROOT}/functions"

echo ""
echo "========================================"
echo "Dotfiles Installer"
echo "Bash ${BASH_VERSION}"
echo "========================================"
echo ""

# -----------------------------------------------------------------------
# Discover steps
# -----------------------------------------------------------------------
# pull-noctalia-settings is interactive (reads a y/N confirmation) and
# would hang an unscoped run -- excluded from the default "run
# everything" pass, only runs when named explicitly:
# ./install.sh pull-noctalia-settings
if [ "$#" -eq 0 ]; then
    mapfile -t step_files < <(find "$FUNCTIONS_DIR" -maxdepth 1 -name '*.sh' -type f ! -name '18-pull-noctalia-settings.sh' | sort)
else
    mapfile -t step_files < <(find "$FUNCTIONS_DIR" -maxdepth 1 -name '*.sh' -type f | sort)
fi

if [ "${#step_files[@]}" -eq 0 ]; then
    echo "No steps found in ${FUNCTIONS_DIR}" >&2
    exit 1
fi

# -----------------------------------------------------------------------
# Filter by requested names (numeric prefix stripped, case-insensitive)
# -----------------------------------------------------------------------
if [ "$#" -gt 0 ]; then
    requested=("$@")
    filtered=()
    for step in "${step_files[@]}"; do
        base="$(basename "$step" .sh)"
        name="$(echo "$base" | sed -E 's/^[0-9]+[-_]?//' | tr '[:upper:]' '[:lower:]')"
        for req in "${requested[@]}"; do
            if [ "$(echo "$req" | tr '[:upper:]' '[:lower:]')" = "$name" ]; then
                filtered+=("$step")
            fi
        done
    done
    step_files=("${filtered[@]}")
    if [ "${#step_files[@]}" -eq 0 ]; then
        echo "No matching steps found." >&2
        exit 1
    fi
fi

# -----------------------------------------------------------------------
# Execute steps
# -----------------------------------------------------------------------
for step in "${step_files[@]}"; do
    write_module_header "Running: $(basename "$step")"
    if source "$step"; then
        echo -e "\033[32m[SUCCESS] $(basename "$step")\033[0m"
    else
        echo -e "\033[31m[FAILED] $(basename "$step")\033[0m"
        exit 1
    fi
done

write_module_header "Installation Complete"
echo "Log out and back into your compositor session for changes to take effect."
