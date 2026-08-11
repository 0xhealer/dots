# Unified Keybind Reference -- Hyprland vs Niri

Single source of truth. When you change a binding, update this table
FIRST, then propagate to configs/hypr/hyprland.lua and
configs/niri/config.kdl.

Noctalia provides the bar, launcher, lock screen, and session/logout
panel on BOTH compositors natively. Vicinae and Spotify were added back
in as secondary apps per request -- Vicinae is NOT the primary
launcher, Noctalia still is.

Hyprland config is now Lua (hyprland.lua) -- Hyprland 0.55 (May 2026,
current stable) deprecated the old hyprlang .conf syntax.

Mod key = Super on both compositors.

| Action              | Hyprland (Lua)                                              | Niri                                                    | Notes |
|---------------------|----------------------------------------------------------------|----------------------------------------------------------|-------|
| Terminal             | `Mod+T` and `Mod+Return`, both -> exec_cmd(terminal)              | `Mod+T` and `Mod+Return`, both -> spawn "kitty"             | Two keys, same action |
| Terminal (VM testing)   | `Mod+Shift+Return` -> exec_cmd("foot")                            | `Mod+Shift+Return { spawn "foot"; }`                         | TEMPORARY -- remove this bind + foot from pacman.txt once off the VM |
| App launcher          | `Mod+D` and `Mod+Space`, both -> exec_cmd("qs -c noctalia-shell --launcher") | `Mod+D` and `Mod+Space`, both -> same spawn        | Confirmed CLI flag |
| Secondary launcher      | `hl.bind(mainMod.." + SHIFT + D", hl.dsp.exec_cmd("vicinae"))`     | `Mod+Shift+D { spawn "vicinae"; }`                          | UNVERIFIED invocation -- guessed, not checked against Vicinae's own docs |
| Music (Spotify)         | `hl.bind(mainMod.." + M", hl.dsp.exec_cmd("spotify"))`             | `Mod+M { spawn "spotify"; }`                                | |
| File manager          | `hl.bind(mainMod.." + E", hl.dsp.exec_cmd(fileManager))`           | `Mod+E { spawn "thunar"; }`                                | |
| Browser               | `hl.bind(mainMod.." + B", hl.dsp.exec_cmd(browser))`               | `Mod+B { spawn "zen-browser"; }`                           | |
| Fullscreen            | `hl.bind(mainMod.." + F", hl.dsp.window.fullscreen())`             | `Mod+F { fullscreen-window; }`                             | niri's own default binds Mod+F to maximize-column instead -- overridden here |
| Close window           | `hl.bind(mainMod.." + Q", hl.dsp.window.close())`                  | `Mod+Q { close-window; }`                                  | |
| Lock screen            | `hl.bind(mainMod.." + Tab", hl.dsp.exec_cmd("qs -c noctalia-shell --lock"))` | `Mod+Tab { spawn "qs" "-c" "noctalia-shell" "--lock"; }`   | Confirmed CLI flag |
| Session/logout panel    | `hl.bind(mainMod.." + Escape", hl.dsp.exec_cmd("qs -c noctalia-shell --control-center"))` | same pattern | UNVERIFIED -- placeholder, no confirmed logout-specific flag found |
| Toggle floating          | `hl.dsp.window.float({action="toggle"})` on Mod+V                | `Mod+V { toggle-window-floating; }`                        | Now the same key (V) on both -- fixed the earlier inconsistency |
| Screenshot (full)         | `grim` via exec_cmd                                             | `Print { screenshot; }`                                     | Different mechanism per leg |

## Blur / transparency
- Hyprland: `decoration.blur` (enabled/size/passes/vibrancy) and
  `decoration.active_opacity` / `inactive_opacity` -- confirmed fields
  from Hyprland's own official example hyprland.lua. Noctalia's own
  surfaces get an additional `layer_rule` blur targeting its namespace;
  the exact rule field names there are carried over from old syntax by
  pattern, not confirmed for the Lua config -- verify against
  https://wiki.hypr.land/Configuring/Basics/Layer-Rules/ if it doesn't
  take effect.
- Niri: got native blur support in 26.04 (April 2026) via
  ext-background-effect. Kitty, Noctalia, and Vicinae are all listed by
  niri's own release notes as already supporting it with zero config on
  the niri side. Nothing needed here for this setup specifically.

## Known gaps -- do not assume parity
- Noctalia v4 (Quickshell/Qt) and v5 (beta) have different launch
  commands and config formats entirely. Confirm which one `yay -S
  noctalia-shell` installs before trusting configs/noctalia/settings.json.
- Dynamic theming needs `templates.activeTemplates` populated in
  settings.json (was empty/missing before -- this was the actual bug).
  Confirmed template ids: kitty, niri, gtk3, gtk4, qt.
