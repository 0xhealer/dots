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
    local backup_dir
    backup_dir="$HOME/.config/backups/$(date +%Y-%m-%d)/${category}"
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

# -----------------------------------------------------------------------
# Distro detection
# -----------------------------------------------------------------------
# Sets (and exports):
#   DOTS_DISTRO  arch | cachyos | ubuntu | kali | debian | fedora
#   DOTS_FAMILY  arch | debian | fedora        (which package manager)
#   DOTS_COL     column used in packages/linux.txt: arch | ubuntu | kali | fedora
# Override with DOTS_DISTRO=<name> (useful for testing). Derivatives are
# mapped through ID_LIKE: EndeavourOS/Manjaro -> arch, Mint/Pop!_OS -> ubuntu.
detect_distro() {
    local id="" like="" line
    if [ -n "${DOTS_DISTRO:-}" ]; then
        id="$DOTS_DISTRO"
    elif [ -r /etc/os-release ]; then
        while IFS= read -r line; do
            case "$line" in
                ID=*)      id="${line#ID=}"; id="${id//\"/}" ;;
                ID_LIKE=*) like="${line#ID_LIKE=}"; like="${like//\"/}" ;;
            esac
        done < /etc/os-release
    fi
    id="$(echo "$id" | tr '[:upper:]' '[:lower:]')"
    like="$(echo "$like" | tr '[:upper:]' '[:lower:]')"

    case "$id" in
        arch|cachyos|ubuntu|kali|debian|fedora) DOTS_DISTRO="$id" ;;
        endeavouros|manjaro|garuda|arcolinux)   DOTS_DISTRO="arch" ;;
        linuxmint|pop|neon|zorin|elementary)    DOTS_DISTRO="ubuntu" ;;
        *)
            case " $like " in
                *" arch "*)                     DOTS_DISTRO="arch" ;;
                *" ubuntu "*)                   DOTS_DISTRO="ubuntu" ;;
                *" debian "*)                   DOTS_DISTRO="debian" ;;
                *" fedora "*|*" rhel "*)        DOTS_DISTRO="fedora" ;;
                *)                              DOTS_DISTRO="unknown" ;;
            esac
            ;;
    esac

    case "$DOTS_DISTRO" in
        arch|cachyos)          DOTS_FAMILY="arch";   DOTS_COL="arch" ;;
        ubuntu)                DOTS_FAMILY="debian"; DOTS_COL="ubuntu" ;;
        kali|debian)           DOTS_FAMILY="debian"; DOTS_COL="kali" ;;   # Debian-named packages
        fedora)                DOTS_FAMILY="fedora"; DOTS_COL="fedora" ;;
        *)                     DOTS_FAMILY="unknown"; DOTS_COL="" ;;
    esac
    export DOTS_DISTRO DOTS_FAMILY DOTS_COL
}
detect_distro

is_arch()   { [ "$DOTS_FAMILY" = "arch" ]; }
is_debian() { [ "$DOTS_FAMILY" = "debian" ]; }
is_fedora() { [ "$DOTS_FAMILY" = "fedora" ]; }

# -----------------------------------------------------------------------
# Package manager abstraction
# -----------------------------------------------------------------------
pkg_refresh() {
    case "$DOTS_FAMILY" in
        arch)   sudo pacman -Syu --noconfirm ;;
        debian) sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y ;;
        fedora) sudo dnf upgrade -y --refresh ;;
    esac
}

# Fedora: one cached list of every available package name (a per-package
# `dnf` query is far too slow).
_dots_dnf_avail_file=""
_dnf_avail() {
    if [ -z "$_dots_dnf_avail_file" ] || [ ! -s "$_dots_dnf_avail_file" ]; then
        _dots_dnf_avail_file="${TMPDIR:-/tmp}/dots-dnf-avail-$$.txt"
        dnf -q repoquery --available --qf '%{name}' 2> /dev/null | sort -u > "$_dots_dnf_avail_file" || true
    fi
    grep -qxF "$1" "$_dots_dnf_avail_file"
}

# True if the package can be installed from the currently enabled repos.
pkg_exists() {
    case "$DOTS_FAMILY" in
        arch)   pacman -Sp "$1" &> /dev/null ;;
        debian) apt-cache policy "$1" 2> /dev/null | awk '/Candidate:/ { if ($2 != "(none)") ok=1 } END { exit !ok }' ;;
        fedora) _dnf_avail "$1" ;;
        *)      return 1 ;;
    esac
}

pkg_installed() {
    case "$DOTS_FAMILY" in
        arch)   pacman -Q "$1" &> /dev/null ;;
        debian) dpkg -s "$1" 2> /dev/null | grep -q '^Status: install ok installed' ;;
        fedora) rpm -q "$1" &> /dev/null ;;
        *)      return 1 ;;
    esac
}

pkg_install() {
    case "$DOTS_FAMILY" in
        arch)   sudo pacman -S --needed --noconfirm "$@" ;;
        debian) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
        fedora) sudo dnf install -y --setopt=strict=0 "$@" ;;
        *)      echo "Unsupported distro: ${DOTS_DISTRO}" >&2; return 1 ;;
    esac
}

# Install a package if it resolves; never fails the caller.
pkg_try_install() {
    local p
    for p in "$@"; do
        if pkg_exists "$p"; then
            pkg_install "$p" && return 0
        fi
    done
    return 1
}

# Print the packages/linux.txt entries for THIS distro, one package per
# line. Format: whitespace-separated columns
#     name   arch   ubuntu   kali   fedora
# ("cachyos" reads the arch column, "debian" reads kali's). A cell may hold
# alternatives separated by "|" (first one the repos actually have wins) or
# "-" for "not packaged here". Lines starting with "[group]" set the group;
# groups named in $DOTS_SKIP_GROUPS (comma separated) are ignored.
# Output: "<group> <cell>"
linux_package_cells() {
    local file="${1:-${DOTFILES_ROOT}/packages/linux.txt}" col group="core" line n c1 c2 c3 c4 cell
    case "$DOTS_COL" in arch) col=2 ;; ubuntu) col=3 ;; kali) col=4 ;; fedora) col=5 ;; *) return 1 ;; esac
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        if [[ "$line" =~ ^[[:space:]]*\[([a-z0-9_-]+)\][[:space:]]*$ ]]; then
            group="${BASH_REMATCH[1]}"
            continue
        fi
        case ",${DOTS_SKIP_GROUPS:-}," in *",${group},"*) continue ;; esac
        read -r n c1 c2 c3 c4 <<< "$line"
        case "$col" in 2) cell="$c1" ;; 3) cell="$c2" ;; 4) cell="$c3" ;; 5) cell="$c4" ;; esac
        [ -z "$cell" ] && continue
        [ "$cell" = "-" ] && continue
        echo "${group} ${n} ${cell}"
    done < "$file"
}

# Resolve "a|b|c" to the first alternative pkg_exists likes. Prints it.
resolve_cell() {
    local cell="$1" alt
    local IFS='|'
    for alt in $cell; do
        if pkg_exists "$alt"; then
            echo "$alt"
            return 0
        fi
    done
    return 1
}

# copy_dotfile, but replaces the literal token @HOME@ with $HOME. For apps
# whose include/import paths must be absolute (kitty, foot, rofi).
copy_dotfile_home() {
    local source="$1" destination="$2"
    if [ ! -e "$source" ]; then
        echo "Source does not exist: $source" >&2
        return 1
    fi
    mkdir -p "$(dirname "$destination")"
    sed "s|@HOME@|${HOME}|g" "$source" > "$destination"
    echo -e "\033[32m[SUCCESS] Deployed: ${destination}\033[0m"
}

# Prints "MAJOR.MINOR" of a program's version, or nothing if unknown.
program_version() {
    "$@" 2> /dev/null | grep -Eo '[0-9]+\.[0-9]+' | head -n1 || true
}

# version_ge A B -> true if A >= B (dotted numeric).
version_ge() {
    [ -n "$1" ] && [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}
