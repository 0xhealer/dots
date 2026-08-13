#!/usr/bin/env bash

set -euo pipefail

# Reconnect stdin to the real terminal, even when this script is being
# read from a pipe (curl ... | bash). Without this, stdin is the pipe
# itself -- sudo usually falls back to /dev/tty directly for its own
# prompt regardless, but that fallback behavior isn't something to
# leave to chance when the whole point is zero interaction after the
# first password entry. This one line makes every subsequent read in
# this script and everything it execs behave as if run normally in a
# terminal.
if [ -t 0 ]; then
    : # already an interactive terminal, nothing to do
elif [ -e /dev/tty ]; then
    exec < /dev/tty
else
    echo "No terminal available (stdin isn't a tty and /dev/tty doesn't exist) -- can't prompt for sudo. Download this script and run it directly instead of piping through curl." >&2
    exit 1
fi

REPO_OWNER="0xhealer"
REPO_NAME="dots"

TEMP_ROOT="$(mktemp -d "/tmp/${REPO_NAME}-XXXXXX")"
ARCHIVE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/main.tar.gz"
ARCHIVE_FILE="${TEMP_ROOT}.tar.gz"


cleanup() {
  rm -rf "$ARCHIVE_FILE"
}

trap cleanup EXIT

echo "Downloading dotfiles..."
max_retries=3
success=false

for i in $(seq 1 "$max_retries"); do
  echo "Downloading (attempt $i/$max_retries)..."
   if curl -fsSL "$ARCHIVE_URL" -o "$ARCHIVE_FILE"; then
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
mkdir -p "$TEMP_ROOT"
tar -xzf "$ARCHIVE_FILE" -C "$TEMP_ROOT" --strip-components=1

INSTALL_SCRIPT="$TEMP_ROOT/install.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "install.sh not found." >&2
    exit 1
fi

echo "Launching installer..."
chmod +x "$INSTALL_SCRIPT"
cd "$TEMP_ROOT"
echo "Repository extracted to: $TEMP_ROOT"
echo ""
# Archive itself is no longer needed once extracted -- clean it up
# explicitly here since the EXIT trap won't fire after exec below (this
# process becomes install.sh, it doesn't return to run the trap).
rm -rf "$ARCHIVE_FILE"
# exec replaces this process with install.sh instead of spawning it as
# a child of a subshell -- one less layer of process nesting for the
# sudo keepalive's background job to potentially get tangled in.
exec "$INSTALL_SCRIPT" "$@"
