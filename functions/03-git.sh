#!/usr/bin/env bash
# functions/03-git.sh — deploy git config. Module name: "git" (matches
# the Windows 10-git.ps1 module name so `./install.sh git` works on both).
set -euo pipefail

write_module_header "Deploying git config"

# Keep whatever was there before -- the Windows leg backs up too.
if [ -e "$HOME/.gitconfig" ]; then
    backup_dir="$(new_backup_directory git)"
    backup_item "$HOME/.gitconfig" "${backup_dir}/.gitconfig"
fi

copy_dotfile "${DOTFILES_ROOT}/configs/git/.gitconfig" "$HOME/.gitconfig"

# The shared configs/git/.gitconfig is written for Windows. Two of its
# settings are wrong on Linux; override them here rather than editing the
# shared file so the Windows leg is untouched.
#
# 1) core.autocrlf = true corrupts things on Linux -- confirmed cause of a
#    real failure: yay's AUR git clones came out CRLF-mangled and makepkg
#    refused to source the PKGBUILDs.
git config --global core.autocrlf input
echo -e "\033[32m[SUCCESS] Overrode core.autocrlf to 'input' for this Linux machine (shared .gitconfig's 'true' is Windows-only)\033[0m"

# 2) credential.helper = manager is Git Credential Manager (Windows). It is
#    not installed here, so every https push/pull would fail with
#    "'credential-manager' is not a git command". Drop it; `gh auth login`
#    followed by `gh auth setup-git` (github-cli is in pacman.txt) wires up
#    a working helper.
git config --global --unset-all credential.helper || true
echo -e "\033[32m[SUCCESS] Removed Windows-only credential.helper 'manager'\033[0m"
echo "!! For https auth to GitHub run: gh auth login && gh auth setup-git"
