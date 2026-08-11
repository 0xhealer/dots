# fish config -- CachyOS box, default shell throughout.

if status is-interactive
    # Starship prompt -- replaces fish's own default greeting/prompt.
    starship init fish | source

    # Disable fish's default startup greeting (the "Welcome to fish"
    # message) since starship's prompt is the intended first thing shown.
    set -g fish_greeting
end
