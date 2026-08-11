#!/usr/bin/env bash
# functions/03-git.sh — deploy git config. Module name: "git" (matches
# the Windows 10-git.ps1 module name so `./install.sh git` works on both).
set -euo pipefail

write_module_header "Deploying git config"
copy_dotfile "${DOTFILES_ROOT}/configs/git/.gitconfig" "$HOME/.gitconfig"

# configs/git/.gitconfig sets core.autocrlf = true, which is correct for
# the Windows leg (LF -> CRLF on checkout) but actively corrupts things
# on Linux -- confirmed cause of a real failure: yay's AUR git clones
# came out CRLF-mangled and makepkg refused to source the PKGBUILDs.
# Override it here rather than editing the shared file, so the Windows
# leg is untouched.
git config --global core.autocrlf input
echo -e "\033[32m[SUCCESS] Overrode core.autocrlf to 'input' for this Linux machine (shared .gitconfig's 'true' is Windows-only)\033[0m"
