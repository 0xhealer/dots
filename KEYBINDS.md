# Unified Keybind Reference -- Hyprland vs Niri

Single source of truth. When you change a binding, update this table
FIRST, then propagate to configs/hypr/hyprland.conf and
configs/niri/config.kdl.

Corrected from an earlier draft: Noctalia provides the bar, launcher,
lock screen, and session/logout panel on BOTH compositors natively --
there is no Waybar, Rofi, Vicinae, swaylock, or wlogout anywhere in this
setup. Don't reintroduce them without a reason; packages/pacman.txt and
packages/aur.txt don't list them for exactly that reason.

Mod key = Super on both compositors.

| Action              | Hyprland                                              | Niri                                                    | Notes |
|---------------------|--------------------------------------------------------|----------------------------------------------------------|-------|
| Terminal             | `bind = $mod, T, exec, kitty`                            | `Mod+T { spawn "kitty"; }`                                 | |
| App launcher          | `bind = $mod, D, exec, qs -c noctalia-shell --launcher`   | `Mod+D { spawn "qs" "-c" "noctalia-shell" "--launcher"; }` | Same Noctalia launcher on both -- confirmed CLI flag |
| File manager          | `bind = $mod, E, exec, thunar`                            | `Mod+E { spawn "thunar"; }`                                | |
| Browser               | `bind = $mod, B, exec, zen-browser`                        | `Mod+B { spawn "zen-browser"; }`                           | |
| Fullscreen            | `bind = $mod, F, fullscreen`                               | `Mod+F { fullscreen-window; }`                             | niri's own default binds Mod+F to maximize-column instead -- overridden here to match Hyprland |
| Close window           | `bind = $mod, Q, killactive`                               | `Mod+Q { close-window; }`                                  | |
| Lock screen            | `bind = $mod, Tab, exec, qs -c noctalia-shell --lock`      | `Mod+Tab { spawn "qs" "-c" "noctalia-shell" "--lock"; }`   | Confirmed CLI flag |
| Session/logout panel    | `bind = $mod, Escape, exec, qs -c noctalia-shell --control-center` | `Mod+Escape { spawn "qs" "-c" "noctalia-shell" "--control-center"; }` | UNVERIFIED -- could not confirm the actual logout/session-panel flag, using --control-center as a placeholder |
| Toggle floating          | `bind = $mod, Space, exec, hyprctl dispatch togglefloating && ...` | `Mod+V { toggle-window-floating; }`                | Different key on each leg currently (Space vs V) -- pick one and make consistent |
| Screenshot (full)         | `bind = $mod, Delete, exec, grim ...`                       | `Print { screenshot; }`                                     | Different mechanism per leg -- niri has a native screenshot action, Hyprland leg still uses grim/slurp |
| Clipboard history          | not currently bound                                          | not currently bound                                          | Removed the earlier rofi/vicinae-piped version -- Noctalia may have its own clipboard history panel, unconfirmed. Don't wire cliphist to a launcher that isn't there anymore |

## Known gaps -- do not assume parity
- Noctalia's exact CLI flags/IPC surface were only partially confirmed
  via search (`--launcher`, `--lock`, `--control-center`, `--set-wallpaper`
  found; a logout/session-specific flag and a clipboard-history flag were
  not). Run `qs -c noctalia-shell --help` (v4) or check the v5 docs before
  trusting the unverified rows above.
- Noctalia v4 (Quickshell/Qt, `qs -c noctalia-shell`) and v5 (beta,
  no Qt) have different launch commands and config file formats
  entirely. Confirm which one `yay -S noctalia-shell` actually installs
  before deploying configs/noctalia/settings.json.
