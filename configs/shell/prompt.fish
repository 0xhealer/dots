# Port of configs/powershell/prompt.ps1 -- fish equivalent.
# starship does the actual prompt; this only reproduces Show-PromptHeader:
# the single-line session banner printed once, before the first prompt.

function __dots_show_prompt_header --on-event fish_prompt
    functions -e __dots_show_prompt_header

    if not command -q fastfetch
        return
    end

    set -l json (fastfetch --logo none -s title:wm:shell --format json 2> /dev/null | string collect)
    if test -z "$json"
        return
    end

    set -l host_name (echo $json | jq -r '.[] | select(.type == "Title") | .result.hostName' 2> /dev/null)
    set -l wm (echo $json | jq -r '.[] | select(.type == "WM") | .result.prettyName // "unknown"' 2> /dev/null)
    set -l shell_name (echo $json | jq -r '.[] | select(.type == "Shell") | .result.exeName' 2> /dev/null)
    set -l shell_ver (echo $json | jq -r '.[] | select(.type == "Shell") | .result.version' 2> /dev/null)

    test -z "$wm" -o "$wm" = null; and set wm unknown

    set -l ip (ip -4 -o addr show scope global 2> /dev/null | string replace -rf '.*inet ([0-9.]+)/.*' '$1' | head -n1)
    test -z "$ip"; and set ip "no ip"

    echo -e "\e[38;5;212m—\e[0m \e[38;5;212m🩸\e[0m \e[1;97m$host_name\e[0m \e[2m·\e[0m \e[97m$ip\e[0m \e[2m·\e[0m \e[38;5;114m$wm\e[0m \e[2m·\e[0m \e[38;5;213m$shell_name $shell_ver\e[0m \e[38;5;212m—\e[0m"
    echo ""
end
