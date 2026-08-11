# Unified Keybind Reference -- Hyprland vs Niri

Single source of truth. When you change a binding, update this table
FIRST, then propagate to configs/hypr/hyprland.lua and
configs/niri/config.kdl.

Noctalia provides the bar, launcher, lock screen, and session/logout
panel on BOTH compositors natively. Vicinae, Rofi, and Spotify were
added back in as secondary/tertiary apps per request -- Vicinae and
Rofi are NOT the primary launcher, Noctalia still is.

Hyprland config is now Lua (hyprland.lua) -- Hyprland 0.55 (May 2026,
current stable) deprecated the old hyprlang .conf syntax.

Mod key = Super on both compositors.

| Action              | Hyprland (Lua)                                              | Niri                                                    | Notes |
|---------------------|----------------------------------------------------------------|----------------------------------------------------------|-------|
| Terminal             | `Mod+T` and `Mod+Return`, both -> exec_cmd(terminal)              | `Mod+T` and `Mod+Return`, both -> spawn "kitty"             | Two keys, same action |
| Terminal (VM testing)   | `Mod+Shift+Return` -> exec_cmd("foot")                            | `Mod+Shift+Return { spawn "foot"; }`                         | TEMPORARY -- remove this bind + foot from pacman.txt once off the VM |
| App launcher          | `Mod+D` and `Mod+Space`, both -> exec_cmd("qs -c noctalia-shell --launcher") | `Mod+D` and `Mod+Space`, both -> same spawn        | Confirmed CLI flag |
| Secondary launcher      | `exec_cmd("vicinae toggle")`, plus `vicinae server` autostarted    | `spawn "vicinae" "toggle"`, plus `vicinae` `server` autostarted | FIXED -- was bare "vicinae" with no server running, confirmed real invocation from Vicinae's own docs |
| Third launcher          | `Mod+Shift+Space` -> `exec_cmd("rofi -show drun")`                 | `Mod+Shift+Space { spawn "rofi" "-show" "drun"; }`           | rofi-wayland in pacman.txt |
| Cheatsheet             | `Mod+Shift+Slash` -> `kitty -e less ~/.config/keybindings.txt`     | `Mod+Shift+Slash { show-hotkey-overlay; }`                   | Niri has this natively with app-name titles; Hyprland uses a static file (same pattern as the NixOS box) |
| Music (Spotify)         | `hl.bind(mainMod.." + M", hl.dsp.exec_cmd("spotify"))`             | `Mod+M { spawn "spotify"; }`                                | |
| File manager          | `hl.bind(mainMod.." + E", hl.dsp.exec_cmd(fileManager))`           | `Mod+E { spawn "thunar"; }`                                | |
| Browser               | `hl.bind(mainMod.." + B", hl.dsp.exec_cmd(browser))`               | `Mod+B { spawn "helium-browser"; }`                        | Switched from Zen to Helium per request. Package `helium-browser-bin`, binary `helium-browser` -- confirmed from the AUR package's own PKGBUILD |
| Fullscreen            | `hl.bind(mainMod.." + F", hl.dsp.window.fullscreen())`             | `Mod+F { fullscreen-window; }`                             | niri's own default binds Mod+F to maximize-column instead -- overridden here |
| Close window           | `hl.bind(mainMod.." + Q", hl.dsp.window.close())`                  | `Mod+Q { close-window; }`                                  | |
| Lock screen            | `hl.bind(mainMod.." + Tab", hl.dsp.exec_cmd("qs -c noctalia-shell --lock"))` | `Mod+Tab { spawn "qs" "-c" "noctalia-shell" "--lock"; }`   | Confirmed CLI flag |
| Session/logout panel    | `hl.bind(mainMod.." + Escape", hl.dsp.exec_cmd("qs -c noctalia-shell --control-center"))` | same pattern | UNVERIFIED -- placeholder, no confirmed logout-specific flag found |
| Toggle floating          | `hl.dsp.window.float({action="toggle"})` on Mod+V                | `Mod+V { toggle-window-floating; }`                        | Now the same key (V) on both -- fixed the earlier inconsistency |
| Screenshot (full)         | `grim` via exec_cmd                                             | `Print { screenshot; }`                                     | Different mechanism per leg |

## Blur / transparency
- The actual bug: Noctalia's `backgroundOpacity` fields default to `1`
  (fully opaque) -- confirmed from Noctalia's own settings-default.json.
  All the compositor-side blur config below was correct from early on,
  but there was nothing transparent for it to blur through. Fixed in
  `configs/noctalia/settings.json` (`bar`, `dock`, `notifications`,
  `osd`, `ui.panelBackgroundOpacity` -- field names and example values
  confirmed from a real user's settings.json in noctalia-shell issue
  #1864).
- Hyprland: `decoration.blur` (enabled/size/passes/vibrancy) and
  `decoration.active_opacity` / `inactive_opacity` -- confirmed fields
  from Hyprland's own official example hyprland.lua. Noctalia's own
  surfaces get an additional `layer_rule` blur targeting its namespace
  -- now confirmed twice over (Vicinae's own docs use the same shape,
  and a real working rice repo, R7rainz/dotfiles, uses this exact rule
  for Noctalia, which is also where `blur_popups` and the namespace's
  trailing `$` came from).
- Niri: got native blur support in 26.04 (April 2026) via
  ext-background-effect. Kitty, Noctalia, and Vicinae are all listed by
  niri's own release notes as already supporting it with zero config on
  the niri side -- confirmed again by Noctalia's own v5 FAQ, which
  describes niri publishing blur regions automatically even for
  transparent bars.

## Shell
- fish is the default login shell throughout (`functions/11-fish.sh`,
  module name "fish"), with starship wired in via
  `configs/shell/config.fish` (`starship init fish | source`) instead of
  fish's own prompt/greeting.

## Theming (wallpaper-driven, central)
- Noctalia's own theming engine already runs a matugen-compatible
  pipeline internally (`theme.source: "wallpaper"` in settings.json) --
  covers kitty, niri, gtk3, gtk4, qt out of the box. Do NOT add a
  separate standalone matugen process on top of this; it would just be
  running the same pipeline twice.
- Rofi and Spicetify aren't in Noctalia's built-in template registry,
  so they're wired in via Noctalia's own user-template mechanism
  instead (`enableUserTheming: true` + `configs/noctalia/user-templates.toml`,
  deployed by `functions/14-matugen-templates.sh`, module name
  "matugen-templates"). Real template files are pulled from
  InioX/matugen-themes at install time rather than hand-written --
  matugen's exact template syntax wasn't something worth guessing at.
- Spicetify template is scaffolded but inert until Spotify itself is
  installed (currently manual/deferred) and Spicetify CLI is set up on
  top of it.
- Do NOT add hyprlock, hypridle, or a separate wallpaper daemon
  (hyprpaper/swww) -- Noctalia already owns lock screen, idle behavior,
  and wallpaper on both compositors. Adding these would create two lock
  screens and two idle daemons fighting over the same job.

## Known gaps -- do not assume parity
- Noctalia v4 (Quickshell/Qt) and v5 (beta) have different launch
  commands and config formats entirely. Confirm which one `yay -S
  noctalia-shell` installs before trusting configs/noctalia/settings.json.
- Dynamic theming needs `templates.activeTemplates` populated in
  settings.json (was empty/missing before -- this was the actual bug).
  Confirmed template ids: kitty, niri, gtk3, gtk4, qt.
