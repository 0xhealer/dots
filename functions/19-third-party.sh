#!/usr/bin/env bash
# functions/19-third-party.sh -- module name: "third-party-apps"
# Things the distro repos don't carry (or carry too old), installed from
# the vendors' own repos / releases. Arch/CachyOS gets these from pacman + the
# AUR (packages/aur.txt), so this step does nothing there.
# Every item is best-effort: one failure is reported, never fatal.
set -euo pipefail

if is_arch; then
    echo -e "\033[33m[SKIP] Arch/CachyOS covers these via pacman + AUR (packages/aur.txt)\033[0m"
    exit 0
fi

ARCH="$(uname -m)"
DEB_ARCH="$(dpkg --print-architecture 2> /dev/null || true)"
try() { "$@" || echo -e "\033[33m[WARN] failed: $*\033[0m"; }

# ---------------------------------------------------------------- neovim
# The nvim config uses vim.pack (nvim >= 0.12); distro packages are older.
write_module_header "neovim (>= 0.12)"
nvim_ver="$(program_version nvim --version)"
if version_ge "$nvim_ver" "0.12"; then
    echo "nvim ${nvim_ver} is new enough"
else
    case "$ARCH" in x86_64) nv=nvim-linux-x86_64 ;; aarch64) nv=nvim-linux-arm64 ;; *) nv="" ;; esac
    if [ -n "$nv" ]; then
        tmp="$(mktemp -d)"
        if curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${nv}.tar.gz" -o "$tmp/nvim.tgz"; then
            mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
            rm -rf "$HOME/.local/opt/nvim"
            tar -xzf "$tmp/nvim.tgz" -C "$tmp"
            mv "$tmp/${nv}" "$HOME/.local/opt/nvim"
            ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
            echo -e "\033[32m[SUCCESS] nvim installed to ~/.local/opt/nvim (linked in ~/.local/bin)\033[0m"
        else
            echo -e "\033[33m[WARN] could not download neovim -- the config needs >= 0.12\033[0m"
        fi
        rm -rf "$tmp"
    fi
fi

# ------------------------------------------------- starship / fastfetch
write_module_header "starship"
if ! test_command_exists starship; then
    try sh -c 'curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"'
fi

write_module_header "fastfetch"
if ! test_command_exists fastfetch && is_debian && { [ "$DEB_ARCH" = "amd64" ] || [ "$DEB_ARCH" = "arm64" ]; }; then
    tmp="$(mktemp -d)"
    if curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${DEB_ARCH}.deb" -o "$tmp/ff.deb"; then
        try sudo apt-get install -y "$tmp/ff.deb"
    fi
    rm -rf "$tmp"
fi

# ------------------------------------------------------------- Tailscale
write_module_header "Tailscale"
if ! test_command_exists tailscale; then
    try sh -c 'curl -fsSL https://tailscale.com/install.sh | sh'
fi

# ----------------------------------------------------------------- Brave
write_module_header "Brave"
if ! test_command_exists brave-browser; then
    try sh -c 'curl -fsS https://dsb.brave.com/install.sh | sh'
fi

# ------------------------------------------- VS Code Insiders (Microsoft)
write_module_header "VS Code Insiders"
if ! test_command_exists code-insiders; then
    if is_debian; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
        echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
            | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        sudo apt-get update
        try pkg_install code-insiders
    elif is_fedora; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        printf '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
            | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
        try pkg_install code-insiders
    fi
fi

# --------------------------------------------- Flatpak apps (Obsidian)
write_module_header "Flatpak: Obsidian"
if ! test_command_exists obsidian; then
    pkg_try_install flatpak || true
    if test_command_exists flatpak; then
        try sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        try sudo flatpak install -y --noninteractive flathub md.obsidian.Obsidian
    fi
fi

# --------------------------------------------------------------- Ghostty
write_module_header "Ghostty"
if ! test_command_exists ghostty; then
    if is_fedora; then
        try sh -c "sudo dnf install -y 'dnf-command(copr)' && sudo dnf copr enable -y pgdev/ghostty && sudo dnf install -y ghostty"
    else
        echo "!! Ghostty has no official ${DOTS_DISTRO} package. kitty and foot are installed and cover the terminal role."
        echo "!! Community .debs: https://github.com/mkasberg/ghostty-ubuntu (Ubuntu) -- install by hand if you want it."
    fi
fi

# ------------------------------------------------------------- Kali extras
if [ "$DOTS_DISTRO" = "kali" ]; then
    echo ""
    echo "!! Kali already ships its own tooling. For the big sets:"
    echo "!!   DOTS_KALI_META=1 ./install.sh packages    (kali-tools-top10/web/passwords/reverse-engineering, several GB)"
fi
echo "!! Not installable here: Helium browser and Proton VPN (Arch-only, see packages/aur.txt) -- dots-browser falls back to Brave/Firefox."
