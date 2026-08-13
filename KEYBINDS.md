# Keybind Reference -- Niri

Single source of truth. When you change a binding, update this table
FIRST, then propagate to configs/niri/config.kdl.

Hyprland was removed from this setup -- Niri only, per request. If
you're looking for the old Hyprland/Niri comparison, dual-compositor
history, or the Hyprland-specific fixes (VM rendering, blur namespace,
etc.), that's in git history before this file was rewritten.

Noctalia provides the bar, launcher, lock screen, and session/logout
panel natively. Vicinae and Rofi are secondary/tertiary launchers added
per request -- Noctalia's own launcher stays primary.

Mod key = Super.

| Action              | Niri                                                        | Notes |
|---------------------|---------------------------------------------------------------|-------|
| Terminal             | `Mod+T` and `Mod+Return`, both -> `spawn "kitty"`             | Two keys, same action |
| Terminal (VM testing)   | `Mod+Shift+Return { spawn "foot"; }`                         | TEMPORARY -- remove this bind + foot from pacman.txt once off the VM |
| App launcher          | `Mod+D` and `Mod+Space`, both -> `spawn "noctalia" "msg" "panel-toggle" "launcher"` | Confirmed v5 IPC command |
| Secondary launcher      | `Mod+Shift+D { spawn "vicinae" "toggle"; }`                    | Needs `vicinae server` autostarted first -- confirmed from Vicinae's own docs |
| Third launcher          | `Mod+Shift+Space { spawn "rofi" "-show" "drun"; }`             | rofi-wayland in pacman.txt |
| Music (Spotify)         | `Mod+M { spawn "spotify"; }`                                  | Spotify itself skipped from aur.txt (manual install) -- bind works once you've installed it some other way |
| File manager          | `Mod+E { spawn "thunar"; }`                                   | |
| Browser               | `Mod+B { spawn "helium-browser"; }`                           | Package `helium-browser-bin` in aur.txt |
| Fullscreen            | `Mod+F { fullscreen-window; }`                                | niri's own default binds Mod+F to maximize-column instead -- overridden here |
| Close window           | `Mod+Q { close-window; }`                                     | |
| Lock screen            | `Mod+Tab { spawn "noctalia" "msg" "session" "lock"; }`         | Confirmed v5 IPC command |
| Session/logout panel    | `Mod+Escape { spawn "noctalia" "msg" "panel-toggle" "control-center"; }` | Confirmed v5 IPC command |
| Toggle floating          | `Mod+V { toggle-window-floating; }`                            | |
| Screenshot (full)         | `Print { screenshot; }`                                        | Native niri action |
| Screenshot (window)       | `Alt+Print { screenshot-window; }`                             | |
| Cheatsheet             | `Mod+Shift+Slash { show-hotkey-overlay; }`                     | Native niri feature -- every bind above has a `hotkey-overlay-title` so it shows app names, not just raw actions |

## Theming (wallpaper-driven, central)
- Noctalia's own theming engine runs a matugen-compatible pipeline
  internally (`theme.source = "wallpaper"` in config.toml) -- covers
  kitty, niri, gtk3, gtk4, qt via `theme.templates.builtin_ids`
  (currently a best guess carried over from v4's confirmed ids, run
  `noctalia theme --list-templates` to confirm v5's actual spelling).
- Rofi and Spicetify aren't in the builtin registry -- wired in via
  `theme.templates.user.<name>` blocks directly in config.toml
  (confirmed real v5 schema from the official example.toml). Template
  files themselves pulled from InioX/matugen-themes at install time
  (functions/14-matugen-templates.sh) rather than hand-written.
- Spicetify template is scaffolded but inert until Spotify itself is
  installed (manual/deferred) and Spicetify CLI is set up.

## Blur / transparency
- The actual blur/frosted-glass toggle is `shell.panel.transparency_mode
  = "glass"` in config.toml (confirmed from Noctalia's own official
  example.toml) -- not something found through trial and error.
  `bar.main.background_opacity`, `notification.background_opacity`,
  `osd.background_opacity`, `lockscreen.blur_intensity`,
  `backdrop.blur_intensity` cover the rest.
- Niri got native blur support in 26.04 (April 2026) via
  ext-background-effect. Kitty, Noctalia, and Vicinae all get it with
  zero config on niri's side, confirmed from niri's own release notes
  and independently from Noctalia's own v5 FAQ.
- Kitty opacity needs explicit `window-rule` blocks (niri has no paired
  active/inactive setting like some compositors do) -- confirmed real
  syntax from niri's own docs across 5 independent sources.
- "Goes opaque when focused" was a CONFIRMED REAL niri bug
  (niri-wm/niri#1823, focus-ring color bleeding into semitransparent
  windows), not a config problem -- kitty specifically named as
  affected in the report. No opacity value fixes it; the workaround
  deployed is `focus-ring { off }` inside kitty's active-state
  window-rule.

## Known gaps -- do not assume parity
- Noctalia v5 is genuinely beta (5.0.0_beta.7) -- re-verify IPC
  commands and config keys periodically against docs.noctalia.dev/v5/
  rather than assuming this file stays accurate forever.
- GUI-made Noctalia changes live at
  `~/.local/state/noctalia/settings.toml`, a separate file from
  `configs/noctalia/config.toml` that this repo manages --
  `functions/18-pull-noctalia-settings.sh` reads that file and shows
  the diff rather than overwriting anything, since it's a set of deltas
  on top of config.toml, not a full config.
