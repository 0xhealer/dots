# Port of configs/powershell/functions/system.ps1 -- fish equivalent.

function psg
    if test (count $argv) -eq 0
        echo "Usage: psg <process_name>"
        return
    end
    command ps aux | command head -n1
    command ps aux | string match -re "$argv[1]"
end

function sysinfo
    echo "=== System Information ==="
    echo "Hostname: "(command hostname)
    echo "Kernel:   "(command uname -srmo)

    if command -q uptime
        echo "Uptime:   "(command uptime -p 2> /dev/null | string replace -r '^up ' '')
    end

    if test -f /proc/meminfo
        set -l total (string match -r '^MemTotal:\s+(\d+)' -g < /proc/meminfo)
        set -l avail (string match -r '^MemAvailable:\s+(\d+)' -g < /proc/meminfo)
        if test -n "$total" -a -n "$avail"
            set -l used_gb (math -s2 "($total - $avail) / 1024 / 1024")
            set -l total_gb (math -s2 "$total / 1024 / 1024")
            echo "Memory:   {$used_gb}GB / {$total_gb}GB"
        end
    end

    if test -f /proc/loadavg
        echo "Load avg: "(string split ' ' < /proc/loadavg)[1..3]
    end

    set -l disk (command df -h / | tail -n1)
    echo "Disk:     "(echo $disk | string match -r '\S+\s+\S+\s+(\S+)\s+(\S+)' -g | string join ' used / ')" total"
end

function install_tools
    echo "Installing fzf and ripgrep..."

    if not command -q fzf
        echo "Installing fzf..."
        winstall fzf
    else
        echo "fzf already installed"
    end

    if not command -q rg
        echo "Installing ripgrep..."
        winstall ripgrep
    else
        echo "ripgrep already installed"
    end

    echo "Tools installation complete!"
    echo "Reload your profile with: reload"
end

# ----------------------------------------------------------------------------
# remove_bloatware
# Linux equivalent of the PowerShell Remove-Bloatware/debloat alias. There is
# no Windows-style bloatware to strip on Linux, so this instead re-runs the
# full installer's package + config steps to bring the machine back in line
# with the repo -- the closest analogue of "redo all the post-install stuff".
# ----------------------------------------------------------------------------
function remove_bloatware
    set -l dir "$HOME/.config/dots-installer"
    set -l script "$dir/install.sh"

    if not test -f "$script"
        mkdir -p "$dir"
        if not curl -fsSL -o "$script" "https://raw.githubusercontent.com/0xhealer/dots/main/install.sh"
            echo "[ERROR] Could not fetch install.sh"
            return 1
        end
        chmod +x "$script"
    end

    bash "$script"
end
alias debloat=remove_bloatware
