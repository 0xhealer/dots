#!/usr/bin/env bash
# functions/00-prerequisites.sh — sanity checks before anything installs.
set -euo pipefail

write_module_header "Checking Internet Connectivity"
if curl -fsSL --max-time 10 -o /dev/null "https://archlinux.org"; then
    echo -e "\033[32m[SUCCESS] Internet connectivity\033[0m"
else
    echo "Internet connection is required" >&2
    exit 1
fi

write_module_header "Verify pacman"
if ! test_command_exists pacman; then
    echo "This installer targets Arch/CachyOS — pacman not found" >&2
    exit 1
fi
echo -e "\033[32m[SUCCESS] pacman detected\033[0m"

write_module_header "Create Common Directories"
for dir in "$HOME/.config" "$HOME/workspace"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "\033[32m[CREATED] ${dir}\033[0m"
    fi
done

write_module_header "Verify not running as root"
if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as your normal user, not root — individual steps sudo where needed" >&2
    exit 1
fi
echo -e "\033[32m[SUCCESS] Running as normal user\033[0m"
