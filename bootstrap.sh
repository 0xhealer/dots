#!/usr/bin/env bash

set -euo pipefail

REPO_OWNER="0xhealer"
REPO_NAME="dots"

TEMP_ROOT="$(mktemp -d "/tmp/${REPO_NAME}-XXXXXX")"
ARCHIVE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/main.tar.gz"
ARCHIVE_FILE="${TEMP_ROOT}.tar.gz"


cleanup() {
  rm -rf "$ARCHIVE_FILE"
  echo ""
  echo "Repository extracted to: "
  echo "  $TEMP_ROOT"
  echo ""
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
(cd "$TEMP_ROOT" && "$INSTALL_SCRIPT")
