# fish config -- default shell throughout.

# ~/.local/bin holds theme-apply's launchers (dots-term, dots-browser) and
# the bat/fd links on Debian-family distros.
fish_add_path -g $HOME/.local/bin

# Syntax colours from the wallpaper-driven palette (see configs/theme).
if test -f $HOME/.config/theme/generated/fish.fish
    source $HOME/.config/theme/generated/fish.fish
end

if status is-interactive
    # Starship prompt -- replaces fish's own default greeting/prompt.
    starship init fish | source

    # Disable fish's default startup greeting (the "Welcome to fish"
    # message) since starship's prompt is the intended first thing shown.
    set -g fish_greeting
end
