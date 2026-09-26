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

# Same stdin safeguard as bootstrap.sh -- belt and suspenders in case
# this ever gets run some other piped way instead of via bootstrap.sh.
# (Test that /dev/tty can actually be OPENED, not just that it exists: with
# no controlling terminal -- cron, CI, some ssh sessions -- the node exists
# but `exec < /dev/tty` fails, and under `set -e` that killed the script.)
if [ ! -t 0 ] && { : < /dev/tty; } 2> /dev/null; then
    exec < /dev/tty
fi

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
# Detach its stdio: otherwise the loop's orphaned `sleep 60` keeps this
# script's stdout pipe open after we exit, so anything reading our output
# (`./install.sh | tee log`) hangs for up to a minute at the very end.
sudo_keepalive < /dev/null > /dev/null 2>&1 &
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
mapfile -t step_files < <(find "$FUNCTIONS_DIR" -maxdepth 1 -name '*.sh' -type f | sort)

if [ "${#step_files[@]}" -eq 0 ]; then
    echo "No steps found in ${FUNCTIONS_DIR}" >&2
    exit 1
fi

# -----------------------------------------------------------------------
# Step metadata
# -----------------------------------------------------------------------
# Only run when asked for by name (never part of a default full run).
OPTIONAL_STEPS=(pull-noctalia-settings)
# If one of these fails, nothing after it makes sense -- abort the run.
CRITICAL_STEPS=(prerequisites)

# "functions/09-noctalia.sh" -> "noctalia" (numeric prefix stripped, lowercase)
step_name() {
    basename "$1" .sh | sed -E 's/^[0-9]+[-_]?//' | tr '[:upper:]' '[:lower:]'
}

in_list() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

# -----------------------------------------------------------------------
# Filter by requested names (case-insensitive) / drop optional steps
# -----------------------------------------------------------------------
filtered=()
if [ "$#" -gt 0 ]; then
    requested=()
    for req in "$@"; do
        requested+=("$(echo "$req" | tr '[:upper:]' '[:lower:]')")
    done
    for step in "${step_files[@]}"; do
        if in_list "$(step_name "$step")" "${requested[@]}"; then
            filtered+=("$step")
        fi
    done
    if [ "${#filtered[@]}" -eq 0 ]; then
        echo "No matching steps found." >&2
        exit 1
    fi
else
    for step in "${step_files[@]}"; do
        if ! in_list "$(step_name "$step")" "${OPTIONAL_STEPS[@]}"; then
            filtered+=("$step")
        fi
    done
fi
step_files=("${filtered[@]}")

# -----------------------------------------------------------------------
# Execute steps
# -----------------------------------------------------------------------
failed_steps=()

for step in "${step_files[@]}"; do
    name="$(step_name "$step")"
    write_module_header "Running: $(basename "$step")"

    # Every step runs in its OWN bash process. Sourcing it inside this
    # `if` would silently disable `set -e` for the whole step (bash
    # ignores errexit anywhere in a condition context), so a failing
    # command mid-step was still reported as [SUCCESS] -- and an
    # `exit 0` inside a step (empty package list, etc.) would have ended
    # the entire installer early. DOTFILES_ROOT is exported above.
    if bash -euo pipefail -c 'source "$1/helpers/common.sh"; source "$2"' _ "$DOTFILES_ROOT" "$step"; then
        echo -e "\033[32m[SUCCESS] $(basename "$step")\033[0m"
    else
        echo -e "\033[31m[FAILED] $(basename "$step")\033[0m"
        failed_steps+=("$name")
        if in_list "$name" "${CRITICAL_STEPS[@]}"; then
            echo "Critical step failed -- aborting." >&2
            break
        fi
    fi
done

if [ "${#failed_steps[@]}" -gt 0 ]; then
    write_module_header "Installation finished WITH FAILURES"
    echo -e "\033[31mFailed steps: ${failed_steps[*]}\033[0m"
    echo "Fix the cause, then re-run just those steps, e.g.: ./install.sh ${failed_steps[*]}"
    exit 1
fi

write_module_header "Installation Complete"
echo "Log out and back into your compositor session for changes to take effect."
