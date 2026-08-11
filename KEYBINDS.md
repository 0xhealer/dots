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
| App launcher          | `Mod+D` and `Mod+Space`, both -> exec_cmd("noctalia msg panel-toggle launcher") | `Mod+D` and `Mod+Space`, both -> same spawn        | v5 IPC command, confirmed from official docs + a real working niri config |
| Secondary launcher      | `exec_cmd("vicinae toggle")`, plus `vicinae server` autostarted    | `spawn "vicinae" "toggle"`, plus `vicinae` `server` autostarted | FIXED -- was bare "vicinae" with no server running, confirmed real invocation from Vicinae's own docs |
| Third launcher          | `Mod+Shift+Space` -> `exec_cmd("rofi -show drun")`                 | `Mod+Shift+Space { spawn "rofi" "-show" "drun"; }`           | rofi-wayland in pacman.txt |
| Cheatsheet             | `Mod+Shift+Slash` -> `kitty -e less ~/.config/keybindings.txt`     | `Mod+Shift+Slash { show-hotkey-overlay; }`                   | Niri has this natively with app-name titles; Hyprland uses a static file (same pattern as the NixOS box) |
| Music (Spotify)         | `hl.bind(mainMod.." + M", hl.dsp.exec_cmd("spotify"))`             | `Mod+M { spawn "spotify"; }`                                | |
| File manager          | `hl.bind(mainMod.." + E", hl.dsp.exec_cmd(fileManager))`           | `Mod+E { spawn "thunar"; }`                                | |
| Browser               | `hl.bind(mainMod.." + B", hl.dsp.exec_cmd(browser))`               | `Mod+B { spawn "helium-browser"; }`                        | Switched from Zen to Helium per request. Package `helium-browser-bin`, binary `helium-browser` -- confirmed from the AUR package's own PKGBUILD |
| Fullscreen            | `hl.bind(mainMod.." + F", hl.dsp.window.fullscreen())`             | `Mod+F { fullscreen-window; }`                             | niri's own default binds Mod+F to maximize-column instead -- overridden here |
| Close window           | `hl.bind(mainMod.." + Q", hl.dsp.window.close())`                  | `Mod+Q { close-window; }`                                  | |
| Lock screen            | `exec_cmd("noctalia msg session lock")`                            | `spawn "noctalia" "msg" "session" "lock"`                    | v5 IPC command, replaces the v4 --lock flag |
| Session/logout panel    | `exec_cmd("noctalia msg panel-toggle control-center")`             | `spawn "noctalia" "msg" "panel-toggle" "control-center"`     | v5 IPC command -- also RESOLVES the old v4 UNVERIFIED placeholder, this one is confirmed |
| Toggle floating          | `hl.dsp.window.float({action="toggle"})` on Mod+V                | `Mod+V { toggle-window-floating; }`                        | Now the same key (V) on both -- fixed the earlier inconsistency |
| Screenshot (full)         | `grim` via exec_cmd                                             | `Print { screenshot; }`                                     | Different mechanism per leg |

## Noctalia: upgraded v4 -> v5 (5.0.0_beta.7)
- v4's opacity/blur troubleshooting (backgroundOpacity defaulting to 1,
  confirmed and fixed via settings.json) is now MOOT -- v5 uses a
  different config file entirely (settings.toml, not settings.json) and
  I do not have confirmed opacity/blur key names for v5's fast-moving
  beta. Rather than guess and repeat the v4 troubleshooting loop,
  configs/noctalia/settings.toml deliberately ONLY contains fields I
  could confirm from a real source (theme, wallpaper). Set
  opacity/blur/anything else via Noctalia's own Settings GUI first --
  it writes the correct schema for whatever your exact build expects --
  then run `functions/18-pull-noctalia-settings.sh` (module name
  "pull-noctalia-settings", NOT part of a normal install.sh run since
  it's interactive) to bring those GUI-made changes back into this repo.
- v5 dropped Quickshell/Qt entirely -- it's a native C++/OpenGL ES
  binary. Launch command changed from `qs -c noctalia-shell` to
  `noctalia --daemon`; all IPC commands changed from CLI flags
  (--launcher, --lock, --control-center) to `noctalia msg <command>`.
  Confirmed from official docs AND cross-checked against a real
  first-hand blog post showing actual working niri config lines.
- Package changed from AUR `noctalia-shell` to `noctalia` -- and
  `noctalia` moved from AUR into Arch's own extra-testing repo about a
  day before this was written. functions/09-noctalia.sh tries pacman
  first, falls back to AUR if extra-testing isn't enabled.
- configs/noctalia/user-templates.toml (Rofi/Spicetify matugen wiring,
  set up while still on v4) is UNVERIFIED against v5 -- it used v4's
  confirmed real path convention (~/.config/noctalia/templates/,
  enableUserTheming in settings.json). Whether v5 uses the same
  mechanism at all is unconfirmed; don't assume Rofi/Spicetify theming
  still works post-upgrade without checking.

## Blur / transparency (compositor side -- still applies regardless of Noctalia version)
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
- v5 is genuinely beta (5.0.0_beta.7) -- things may change under you on
  updates. Re-verify IPC commands and config keys periodically against
  docs.noctalia.dev/v5/ rather than assuming this file stays accurate.
- Noctalia's built-in template registry (kitty/niri/gtk3/gtk4/qt) was
  confirmed for v4. Whether v5 has the same registry, same template ids,
  or needs re-activating is unconfirmed -- check before assuming
  wallpaper-driven kitty/gtk theming still works post-upgrade.
- Hyprland's noctalia-blur layer_rule namespace pattern
  (noctalia-background-.*$) was confirmed for v4's Quickshell-rendered
  surfaces. v5's native renderer may use different layer-shell
  namespaces -- verify with `hyprctl layers` rather than assume.
