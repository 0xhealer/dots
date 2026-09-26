#!/usr/bin/env bash
# functions/00-prerequisites.sh — sanity checks before anything installs.
set -euo pipefail

write_module_header "Verify not running as root"
if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as your normal user, not root — individual steps sudo where needed" >&2
    exit 1
fi
echo -e "\033[32m[SUCCESS] Running as normal user\033[0m"

write_module_header "Detecting distribution"
if [ "$DOTS_FAMILY" = "unknown" ]; then
    echo "Unsupported distro. Supported: Arch, CachyOS, Ubuntu, Kali (and Debian), Fedora." >&2
    echo "Force one with e.g. DOTS_DISTRO=ubuntu ./install.sh" >&2
    exit 1
fi
echo -e "\033[32m[SUCCESS] ${DOTS_DISTRO} (package family: ${DOTS_FAMILY}, package column: ${DOTS_COL})\033[0m"

write_module_header "Checking Internet Connectivity"
if curl -fsSL --max-time 10 -o /dev/null "https://github.com"; then
    echo -e "\033[32m[SUCCESS] Internet connectivity\033[0m"
else
    echo "Internet connection is required" >&2
    exit 1
fi

write_module_header "Verify package manager"
case "$DOTS_FAMILY" in
    arch)   test_command_exists pacman   || { echo "pacman not found" >&2; exit 1; } ;;
    debian) test_command_exists apt-get  || { echo "apt-get not found" >&2; exit 1; } ;;
    fedora) test_command_exists dnf      || { echo "dnf not found" >&2; exit 1; } ;;
esac
echo -e "\033[32m[SUCCESS] package manager detected\033[0m"

# Ubuntu keeps most of what this installs (rofi, kitty, foot, sqlmap, ...)
# in "universe". Fresh installs usually have it, minimal ones may not.
if [ "$DOTS_DISTRO" = "ubuntu" ]; then
    write_module_header "Ensuring Ubuntu 'universe' is enabled"
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
    sudo add-apt-repository -y universe
fi

write_module_header "Create Common Directories"
for dir in "$HOME/.config" "$HOME/.local/bin" "$HOME/workspace"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "\033[32m[CREATED] ${dir}\033[0m"
    fi
done
