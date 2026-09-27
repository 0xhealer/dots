#!/usr/bin/env bash
# functions/08-niri.sh -- module name: "niri"
# Installs niri if the distro package step could not, then deploys its config.
set -euo pipefail

build_niri_from_source() {
    # Debian family (Kali, Debian, older Ubuntu) has no niri package. Build
    # the release from source, install it system-wide under /usr/local with
    # the session files (so it shows up in the display manager).
    write_module_header "Building niri from source (no ${DOTS_DISTRO} package) -- this takes a while"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        gcc clang pkg-config libudev-dev libgbm-dev libxkbcommon-dev libegl1-mesa-dev \
        libwayland-dev libinput-dev libdbus-1-dev libsystemd-dev libseat-dev \
        libpipewire-0.3-dev libpango1.0-dev libdisplay-info-dev git curl

    # A `cargo` shim can exist on PATH (rustup installs one even before a
    # toolchain is selected) while still failing at invocation time with
    # "could not choose a version of cargo to run... no default is
    # configured". Checking `command -v cargo` alone missed that case, so
    # actually invoke it and fall through to `rustup default stable`
    # whenever it does not work.
    if ! test_command_exists cargo || ! cargo --version > /dev/null 2>&1; then
        if test_command_exists rustup; then
            rustup default stable
        else
            curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
        fi
        # shellcheck disable=SC1091
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    fi

    if ! cargo --version > /dev/null 2>&1; then
        echo -e "\033[31m[ERROR] cargo is still not usable after rustup setup -- aborting niri build\033[0m" >&2
        return 1
    fi

    local src
    src="$(mktemp -d)"
    git clone --depth 1 https://github.com/niri-wm/niri.git "$src/niri"
    (cd "$src/niri" && cargo build --release --locked)

    sudo install -Dm755 "$src/niri/target/release/niri" /usr/local/bin/niri
    [ -f "$src/niri/resources/niri-session" ] && sudo install -Dm755 "$src/niri/resources/niri-session" /usr/local/bin/niri-session
    [ -f "$src/niri/resources/niri.desktop" ] && sudo install -Dm644 "$src/niri/resources/niri.desktop" /usr/local/share/wayland-sessions/niri.desktop
    [ -f "$src/niri/resources/niri-portals.conf" ] && sudo install -Dm644 "$src/niri/resources/niri-portals.conf" /usr/local/share/xdg-desktop-portal/niri-portals.conf
    for unit in niri.service niri-shutdown.target; do
        if [ -f "$src/niri/resources/$unit" ]; then
            sudo install -Dm644 "$src/niri/resources/$unit" "/etc/systemd/user/$unit"
            sudo sed -i 's|/usr/bin/niri|/usr/local/bin/niri|g' "/etc/systemd/user/$unit"
        fi
    done
    sudo sed -i 's|/usr/bin/niri|/usr/local/bin/niri|g' /usr/local/share/wayland-sessions/niri.desktop 2> /dev/null || true
    rm -rf "$src"
    echo -e "\033[32m[SUCCESS] niri built and installed to /usr/local\033[0m"
}

write_module_header "Ensuring niri is installed"
if ! test_command_exists niri; then
    case "$DOTS_FAMILY" in
        arch)
            pkg_try_install niri || echo -e "\033[33m[WARN] niri not available from the repos\033[0m" ;;
        fedora)
            if ! pkg_try_install niri; then
                echo -e "\033[33m[INFO] niri not in Fedora's repos -- enabling COPR yalter/niri\033[0m"
                sudo dnf install -y 'dnf-command(copr)' && sudo dnf copr enable -y yalter/niri && sudo dnf install -y niri \
                    || echo -e "\033[33m[WARN] Could not install niri on Fedora\033[0m"
            fi ;;
        debian)
            if ! pkg_try_install niri; then
                if [ "$DOTS_DISTRO" = "ubuntu" ] && sudo add-apt-repository -y ppa:avengemedia/danklinux 2> /dev/null && sudo apt-get update && pkg_try_install niri; then
                    :
                else
                    build_niri_from_source || echo -e "\033[33m[WARN] Building niri failed -- see https://github.com/niri-wm/niri/wiki/Getting-Started\033[0m"
                fi
            fi ;;
    esac
fi

write_module_header "Deploying Niri config"
NIRI_DIR="$HOME/.config/niri"
mkdir -p "$NIRI_DIR"
copy_dotfile "${DOTFILES_ROOT}/configs/niri/config.kdl" "$NIRI_DIR/config.kdl"

# `include` needs niri 25.11+. Older niri gets the generated colours spliced
# into config.kdl instead; theme-apply redoes that whenever the palette changes.
version="$(program_version niri --version)"
mkdir -p "$HOME/.config/theme"
if [ -n "$version" ] && ! version_ge "$version" "25.11"; then
    echo -e "\033[33m[INFO] niri ${version} has no 'include' -- theme will be spliced into config.kdl instead\033[0m"
    cp "$NIRI_DIR/config.kdl" "$NIRI_DIR/config.kdl.base"
    touch "$HOME/.config/theme/.niri-inline"
else
    rm -f "$HOME/.config/theme/.niri-inline" "$NIRI_DIR/config.kdl.base"
fi

if test_command_exists niri && [ -f "$HOME/.config/theme/generated/niri.kdl" ]; then
    niri validate --config "$NIRI_DIR/config.kdl" || echo "!! niri validate reported problems -- check output above before logging into a Niri session with this config"
fi
