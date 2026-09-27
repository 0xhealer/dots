# Port of configs/powershell/functions/utils.ps1 -- fish equivalent.

function mkcd
    if test (count $argv) -eq 0
        echo "Usage: mkcd <path>"
        return 1
    end
    mkdir -p $argv[1]
    and cd $argv[1]
end

function extract
    if test (count $argv) -eq 0
        echo "Usage: extract <file>"
        return 1
    end
    set -l path $argv[1]
    if not test -f "$path"
        echo "'$path' is not a valid file"
        return 1
    end

    switch $path
        case '*.zip'
            unzip "$path"
        case '*.tar.gz' '*.tgz'
            tar xzf "$path"
        case '*.tar.bz2' '*.tbz2'
            tar xjf "$path"
        case '*.tar.xz'
            tar xJf "$path"
        case '*.tar.zst'
            tar --zstd -xf "$path"
        case '*.tar'
            tar xf "$path"
        case '*.7z'
            7z x "$path"
        case '*.gz'
            tar xzf "$path"
        case '*'
            echo "'$path' cannot be extracted"
    end
end

function hgrep
    if test (count $argv) -eq 0
        history search --contains ""
        return
    end
    history search --contains "$argv[1]"
end

function dirsize
    set -l path "."
    if test (count $argv) -gt 0
        set path $argv[1]
    end
    command du -sh "$path" 2> /dev/null | string split \t | head -n1
end

function path
    string split ':' $PATH | awk '{ print NR"\t"$0 }'
end
