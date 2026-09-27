# fish config -- default shell throughout.
#
# functions/11-fish.sh deploys configs/shell/config.fish (this file) to
# ~/.config/fish/config.fish, and the rest of this directory to
# ~/.config/fish/dots/ -- deliberately NOT ~/.config/fish/functions/, whose
# autoload semantics (one file per function, loaded lazily on first call)
# don't fit this profile's dependency-ordered, "load everything up front"
# design, the same way user_profile.ps1 works on the Windows side.

if not set -q EDITOR
    set -gx EDITOR nvim
end

# ~/.local/bin holds theme-apply's launchers (dots-term, dots-browser) and
# the bat/fd links on Debian-family distros.
fish_add_path -g $HOME/.local/bin

set -l dots_dir "$HOME/.config/fish/dots"

set -l parts \
    functions/system.fish \
    functions/utils.fish \
    aliases.fish \
    fzf.fish \
    keybinds.fish

for part in $parts
    set -l part_path "$dots_dir/$part"
    if not test -f "$part_path"
        echo "[WARN] profile: missing $part" >&2
        continue
    end
    source "$part_path"
end

if command -q zoxide
    zoxide init fish | source
end

if status is-interactive
    # Starship prompt -- replaces fish's own default greeting/prompt.
    starship init fish | source

    # Disable fish's default startup greeting (the "Welcome to fish"
    # message) since starship's prompt is the intended first thing shown.
    set -g fish_greeting
end

# Syntax colours from the wallpaper-driven palette (see configs/theme).
if test -f $HOME/.config/theme/generated/fish.fish
    source $HOME/.config/theme/generated/fish.fish
end

# Single-line session header (hostname / ip / WM / shell) -- last, so
# starship and the theme are already active when it prints.
if status is-interactive
    set -l prompt_path "$dots_dir/prompt.fish"
    if test -f "$prompt_path"
        source "$prompt_path"
    end
end
