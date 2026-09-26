#!/usr/bin/env bash
# bootstrap.sh -- one-liner entrypoint:
#   curl -fsSL https://raw.githubusercontent.com/0xhealer/dots/main/bootstrap.sh | bash
# Extra arguments are passed to install.sh (step names):
#   curl -fsSL .../bootstrap.sh | bash -s -- starship git

set -euo pipefail

# EVERYTHING lives inside main(), called on the last line. When this script
# is piped into bash, bash reads it from stdin as it goes. The stdin
# reconnect below (`exec < /dev/tty`) swaps that stdin for the terminal, so
# any line bash had not yet read would then be read from the KEYBOARD and
# the one-liner would just hang. Wrapping the body in a function makes bash
# parse the whole script before running any of it.
main() {
    # Reconnect stdin to the real terminal, even when this script is being
    # read from a pipe (curl ... | bash), so sudo/passwords can be typed.
    # (Test that /dev/tty can actually be OPENED, not just that it exists.)
    if [ -t 0 ]; then
        : # already an interactive terminal, nothing to do
    elif { : < /dev/tty; } 2> /dev/null; then
        exec < /dev/tty
    else
        echo "No terminal available (stdin isn't a tty and /dev/tty can't be opened) -- can't prompt for sudo. Download this script and run it directly instead of piping through curl." >&2
        exit 1
    fi

    local repo_owner="0xhealer"
    local repo_name="dots"

    local temp_root archive_url archive_file
    temp_root="$(mktemp -d "/tmp/${repo_name}-XXXXXX")"
    archive_url="https://github.com/${repo_owner}/${repo_name}/archive/refs/heads/main.tar.gz"
    archive_file="${temp_root}.tar.gz"

    # Only fires on early exits; the success path execs (no trap) and removes
    # the archive explicitly below.
    trap 'rm -f "$archive_file"' EXIT

    echo "Downloading dotfiles..."
    local max_retries=3
    local success=false
    local i

    for i in $(seq 1 "$max_retries"); do
        echo "Downloading (attempt $i/$max_retries)..."
        if curl -fsSL "$archive_url" -o "$archive_file"; then
            success=true
            break
        fi
        sleep 2
    done

    if [ "$success" != true ]; then
        echo "Failed to download repository after $max_retries attempts." >&2
        exit 1
    fi

    echo "Extracting archive..."
    tar -xzf "$archive_file" -C "$temp_root" --strip-components=1

    local install_script="$temp_root/install.sh"

    if [ ! -f "$install_script" ]; then
        echo "install.sh not found." >&2
        exit 1
    fi

    echo "Launching installer..."
    chmod +x "$install_script"
    cd "$temp_root"
    echo "Repository extracted to: $temp_root"
    echo ""
    # Archive itself is no longer needed once extracted.
    rm -f "$archive_file"
    # exec replaces this process with install.sh instead of spawning it as a
    # child -- one less layer of process nesting for the sudo keepalive's
    # background job to get tangled in.
    exec "$install_script" "$@"
}

main "$@"
