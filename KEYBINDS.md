# Keybind Reference -- Hyprland and niri

Single source of truth: update this table first, then `configs/niri/config.kdl`,
`configs/hypr/hyprland.lua`, `configs/hypr/hyprland.conf` and
`assets/keybindings.txt` (the cheatsheet Hyprland shows on Mod+Shift+/).

Launcher is Rofi. Noctalia (bar/lock/control center) is optional and only
runs where it is installed (Arch/CachyOS). Mod key = Super.

| Action                    | Keys                                   | Notes |
|---------------------------|----------------------------------------|-------|
| Terminal                  | `Mod+T`, `Mod+Return`                  | `dots-term`: kitty > ghostty > foot |
| Terminal: ghostty / foot  | `Mod+Shift+Return` / `Mod+Ctrl+Return` | |
| Launcher (apps)           | `Mod+D`, `Mod+Space`                   | `rofi -show drun` |
| Rofi run / windows        | `Mod+Shift+D` / `Mod+Shift+Space`      | |
| Pick wallpaper + re-theme | `Mod+W`                                | `theme-apply --pick` |
| Random wallpaper          | `Mod+Shift+W`                          | `theme-apply --random` |
| Music                     | `Mod+M`                                | Spotify, manual install |
| File manager              | `Mod+E`                                | Thunar |
| Browser                   | `Mod+B`                                | `dots-browser`: helium > brave > firefox |
| Fullscreen / close / float| `Mod+F` / `Mod+Q` / `Mod+V`            | |
| Lock / control center     | `Mod+Tab` / `Mod+Escape`               | Noctalia, if installed |
| Screenshot                | niri `Print`, `Alt+Print`; Hyprland `Delete`, `Mod+Delete` | |
| Workspaces 1-4            | `Mod+1..4`; move: niri `Mod+Ctrl+1..4`, Hyprland `Mod+Shift+1..4` | |
| Cheatsheet                | `Mod+Shift+Slash`                      | niri: built-in overlay |

## Theming
One palette for everything: `~/.config/theme/theme.conf`, derived from the
wallpaper by `theme-apply` and rendered into kitty, foot, ghostty, rofi,
Hyprland, niri and fish (and the Limine boot menu via `./install.sh limine-theme`).
See README "Theming".
