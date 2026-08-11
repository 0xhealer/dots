-- Hyprland config -- CachyOS box. Lua format (Hyprland 0.55+, current
-- stable). The old hyprland.conf/hyprlang syntax is deprecated -- this
-- replaces it rather than sitting on a format already being phased out.
-- Keybinds mirror KEYBINDS.md -- update that table first, then this file.
--
-- TEMPORARY: this file has a VM-testing-only foot terminal bind
-- (Mod+Shift+Return). Search "TEMPORARY" in this file and remove that
-- bind, plus "foot" from packages/pacman.txt, once off the VM.

------------------
---- MONITORS ----
------------------
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

---------------------
---- MY PROGRAMS ----
---------------------
local terminal = "kitty"
local fileManager = "thunar"
local browser = "helium-browser"

-------------------
---- AUTOSTART ----
-------------------
-- v5: "noctalia --daemon" replaces "qs -c noctalia-shell" entirely --
-- v5 is a native binary, no Quickshell/Qt runtime involved at all.
-- Confirmed from Noctalia's own docs ("supports a --daemon flag for
-- compositors that expect the startup process to fork and return").
--
-- "vicinae server" MUST be running before "vicinae toggle" does
-- anything -- confirmed from Vicinae's own docs (docs.vicinae.com).
hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia --daemon")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("vicinae server")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        layout = "dwindle",
    },
    decoration = {
        rounding = 8,
        -- Transparency -- confirmed fields from Hyprland's own example
        -- config. 1.0 = opaque; lower = more see-through.
        active_opacity = 0.95,
        inactive_opacity = 0.85,
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            vibrancy = 0.17,
        },
    },
})

-- Blur/transparency for Noctalia's own surfaces (bar, panels, dock,
-- notifications). UNVERIFIED FOR v5: this namespace pattern
-- ("noctalia-background-.*$") was confirmed for v4's Quickshell-based
-- layer-shell surfaces. v5 is a from-scratch native renderer -- I have
-- no confirmation its layer-shell surface namespaces are named the
-- same way. Left as-is since it's a reasonable starting guess, but
-- verify with `hyprctl layers` while Noctalia v5 is running and adjust
-- the namespace match if it doesn't actually target anything.
hl.layer_rule({
    name = "noctalia-blur",
    match = { namespace = "noctalia-background-.*$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.5,
})

hl.layer_rule({
    name = "vicinae-blur",
    match = { namespace = "vicinae" },
    blur = true,
    ignore_alpha = 0,
})

---------------------
---- KEYBINDINGS ----
---------------------
-- (app name) -- for a Hyprland cheatsheet, see the Mod+Shift+Slash bind
-- at the bottom, which opens assets/keybindings.txt. Hyprland has no
-- built-in hotkey-overlay like Niri does, so this is a plain text file
-- instead -- same pattern already used on the NixOS box.
local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))                          -- (kitty)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))                     -- (kitty)
-- TEMPORARY -- VM testing only, remove this bind (and foot from
-- packages/pacman.txt) once off the VM. kitty can fail to launch or
-- render under VMware's SVGA virtual GPU; foot works with much less
-- GPU capability.
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("foot"))               -- (foot, VM testing only)

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher")) -- (Noctalia launcher)
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher")) -- (Noctalia launcher)
-- Fixed: "vicinae toggle", not bare "vicinae" -- see AUTOSTART note above.
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("vicinae toggle"))          -- (Vicinae, secondary launcher)
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.exec_cmd("rofi -show drun"))     -- (Rofi, third launcher)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("spotify"))                        -- (Spotify -- manual install, skipped in aur.txt)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))                      -- (Thunar)
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))                          -- (Helium Browser)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())                        -- (fullscreen toggle)
hl.bind(mainMod .. " + Q", hl.dsp.window.close())                             -- (close window)
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("noctalia msg session lock"))    -- (Noctalia lock screen)
-- v5: confirmed IPC command, replaces the old v4 --control-center flag
-- (which was itself an UNVERIFIED placeholder that never got confirmed).
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center")) -- (Noctalia control center)
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))        -- (toggle floating)

hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("grim ~/Pictures/$(date +%s).png"))       -- (grim, full screenshot)
hl.bind("Delete", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/$(date +%s).png"))     -- (grim+slurp, region screenshot)

-- Cheatsheet: all keybinds + app names, deployed by functions/10-assets.sh
hl.bind(mainMod .. " + SHIFT + Slash", hl.dsp.exec_cmd("kitty -e less ~/.config/keybindings.txt")) -- (keybindings.txt cheatsheet)

-- Workspaces
for i = 1, 4 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
