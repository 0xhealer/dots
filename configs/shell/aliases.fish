# Port of configs/powershell/aliases.ps1 -- fish equivalent.
# Anything Linux already provides a good native version of (ps, df, du,
# grep, which, top) is left alone rather than shadowed with a worse one.

function .. ; cd ..; end
function ... ; cd ../..; end
function .... ; cd ../../..; end
# `cd -` (previous directory) and `~` (home) are already native fish
# behavior -- fish rejects `~` and `-` as function names outright, so
# unlike the PowerShell side there is nothing to port for those two.

# ============================================================================
# LS VARIANTS
# ============================================================================
if command -q eza
    function l;  eza -l --group --color=always --group-directories-first $argv; end
    function ls; eza -al --group --header --icons --group-directories-first $argv; end
    function ll; eza -la --group --icons --group-directories-first $argv; end
    function la; eza -la --group --icons --group-directories-first $argv; end
    function lt; eza --tree --level=2 --icons $argv; end
    function lh; eza -la --group --sort=modified --reverse $argv; end
else
    function l;  command ls $argv; end
    function ll; command ls -la $argv; end
    function la; command ls -A $argv; end
    function lt; command ls -R $argv; end
    function lh; command ls -lat $argv; end
end

# ============================================================================
# FILE OPERATIONS
# ============================================================================
function cp; command cp -i $argv; end
function mv; command mv -i $argv; end
function rm; command rm -i $argv; end
function mkdir; command mkdir -pv $argv; end

# ============================================================================
# SYSTEM INFO (things without a good native one-liner already)
# ============================================================================
function dfh; command df -h $argv; end
function cputop; command ps aux --sort=-%cpu | head -n 16; end
function memtop; command ps aux --sort=-%mem | head -n 6; end

# ============================================================================
# NETWORK
# ============================================================================
function myip
    set -l local (ip -4 -o addr show scope global | string replace -rf '.*inet ([0-9.]+)/.*' '$1' | head -n1)
    echo "Local:    $local"
    echo -n "External: "
    curl -s https://ifconfig.me
    echo
end
function ports; command ss -tulnp $argv; end
function listening; command ss -tlnp $argv; end

# ============================================================================
# PACKAGE MANAGEMENT (mapped to whichever package manager this distro uses --
# same idea as the winget wrappers, different tool underneath)
# ============================================================================
function winstall
    if command -q pacman
        sudo pacman -S --needed $argv
    else if command -q apt-get
        sudo apt-get install -y $argv
    else if command -q dnf
        sudo dnf install -y $argv
    end
end
function search
    if command -q pacman
        pacman -Ss $argv
    else if command -q apt-cache
        apt-cache search $argv
    else if command -q dnf
        dnf search $argv
    end
end
function update
    if command -q pacman
        sudo pacman -Sy
    else if command -q apt-get
        sudo apt-get update
    else if command -q dnf
        sudo dnf check-update
    end
end
function upgrade
    if command -q pacman
        sudo pacman -Syu
    else if command -q apt-get
        sudo apt-get upgrade -y
    else if command -q dnf
        sudo dnf upgrade -y
    end
end
function remove
    if command -q pacman
        sudo pacman -Rns $argv
    else if command -q apt-get
        sudo apt-get remove -y $argv
    else if command -q dnf
        sudo dnf remove -y $argv
    end
end
function uplist
    if command -q pacman
        pacman -Qu
    else if command -q apt-get
        apt list --upgradable
    else if command -q dnf
        dnf check-update
    end
end

# ============================================================================
# GIT
# ============================================================================
function g;      git $argv; end
function gs;     git status $argv; end
function ga;     git add $argv; end
function gaa;    git add -A; end
function gc;     git commit $argv; end
function gcm;    git commit -m $argv; end
function gp;     git push $argv; end
function gpu;    git push -u origin HEAD; end
function gpl;    git pull $argv; end
function gco;    git checkout $argv; end
function gb;     git branch $argv; end
function gd;     git diff $argv; end
function gl;     git log --oneline --graph --decorate; end
function gclone; git clone $argv; end

# ============================================================================
# EDITORS AND CONFIG
# ============================================================================
function v;  nvim $argv; end
function vv; nvim .; end
function e;  micro $argv; end
function n;  nano $argv; end

function edit_profile; $EDITOR $HOME/.config/fish/config.fish; end
function reload; source $HOME/.config/fish/config.fish; echo "Reloaded config"; end
function nvimrc; $EDITOR $HOME/.config/nvim/init.lua; end

# ============================================================================
# DIRECTORY SHORTCUTS
# ============================================================================
function g.;  cd $HOME/.config; end
function dl;  cd $HOME/Downloads; end
function doc; cd $HOME/Documents; end
function vid; cd $HOME/Videos; end

# ============================================================================
# UTILITIES
# ============================================================================
function c; clear; end
function now; date "+%Y-%m-%d %H:%M:%S"; end
function week; date +%V; end
function k9; kill -9 $argv[1]; end
function untar; tar -xvf $argv; end
function ungz; tar -xzvf $argv; end
function weather; curl "wttr.in/?u"; end
function ff; fastfetch; end
