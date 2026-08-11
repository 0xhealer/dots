#!/usr/bin/env bash
# helpers/common.sh — bash equivalent of helpers/common.ps1.
# Sourced by install.sh before running functions/*.sh steps.

write_module_header() {
    local title="$1"
    echo ""
    echo "========================================"
    echo -e "\033[33m${title}\033[0m"
    echo "========================================"
    echo ""
}

test_command_exists() {
    command -v "$1" &> /dev/null
}

new_backup_directory() {
    local category="$1"
    local backup_dir="$HOME/.config/backups/$(date +%Y-%m-%d)/${category}"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

backup_item() {
    local source="$1"
    local destination="$2"
    [ -e "$source" ] || return 0
    cp -r "$source" "$destination"
    echo -e "\033[32m[SUCCESS] Backed up: ${source}\033[0m"
}

copy_dotfile() {
    local source="$1"
    local destination="$2"
    if [ ! -e "$source" ]; then
        echo "Source does not exist: $source" >&2
        return 1
    fi
    mkdir -p "$(dirname "$destination")"
    cp -r "$source" "$destination"
    echo -e "\033[32m[SUCCESS] Deployed: ${destination}\033[0m"
}

get_package_list() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "Package file not found: $file" >&2
        return 1
    fi
    grep -v '^\s*#' "$file" | grep -v '^\s*$'
}
