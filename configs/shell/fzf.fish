# Port of configs/powershell/fzf.ps1 -- fish equivalent.
# fish's own fzf.fish plugin isn't assumed to be installed; this wires up
# the same handful of fzf-powered helpers directly, plus fzf's own
# key-bindings script when it ships one (Debian/Fedora package it under
# /usr/share/fzf, Arch's fzf package installs a fish binding function).

if command -q fzf
    function vf --description 'fuzzy-pick a file and open it in $EDITOR'
        set -l file (fzf --preview 'bat --color=always {} 2>/dev/null')
        if test -z "$file"
            set file (fzf)
        end
        if test -n "$file"
            $EDITOR "$file"
        end
    end

    function fkill --description 'fuzzy-pick process(es) and kill them'
        set -l signal 9
        if test (count $argv) -gt 0
            set signal $argv[1]
        end
        set -l pids (command ps -eo pid,pcpu,comm --sort=-pcpu | fzf --multi --header-lines=1 | awk '{print $1}')
        if test -n "$pids"
            for pid in $pids
                kill -$signal $pid
            end
        end
    end

    set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --info=inline"

    if command -q fd
        set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
        set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
        set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"
    end

    # fzf's own fish key-bindings (Ctrl+T file widget, Ctrl+R history,
    # Alt+C cd), when the package ships them.
    if functions -q fzf_key_bindings
        fzf_key_bindings
    end
end
