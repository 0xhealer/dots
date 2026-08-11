-- Hyprland config -- CachyOS box. Lua format (Hyprland 0.55+, current
-- stable). The old hyprland.conf/hyprlang syntax is deprecated -- this
-- replaces it rather than sitting on a format already being phased out.
-- Keybinds mirror KEYBINDS.md -- update that table first, then this file.

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
local browser = "zen-browser"

-------------------
---- AUTOSTART ----
-------------------
-- NOTE: "qs -c noctalia-shell" is the v4 (Quickshell) launch command.
-- Noctalia v5 dropped Quickshell/Qt -- if the AUR package is v5 this is
-- wrong. Check `noctalia-shell --version` before trusting this.
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c noctalia-shell")
    hl.exec_cmd("wl-paste --watch cliphist store")
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
-- notifications). Namespace pattern and the general approach are
-- confirmed from Noctalia's own Hyprland compositor-settings docs;
-- the exact layer_rule field names below (blur/ignore_alpha as direct
-- keys) are carried over from the old layerrule syntax by pattern, NOT
-- confirmed against a real Lua-config example -- check
-- https://wiki.hypr.land/Configuring/Basics/Layer-Rules/ if this
-- doesn't take effect.
hl.layer_rule({
    name = "noctalia-blur",
    match = { namespace = "noctalia-background-.*" },
    blur = true,
    ignore_alpha = 0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs -c noctalia-shell --launcher"))
-- Vicinae as a secondary launcher (Noctalia's is primary on Mod+D) --
-- installed via packages/aur.txt but its keybind/CLI invocation here is
-- a guess (`vicinae` with no args, assuming it opens its own window)
-- not confirmed against actual usage docs.
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("vicinae"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("qs -c noctalia-shell --lock"))
-- UNVERIFIED: could not confirm the session/logout-panel CLI flag --
-- see KEYBINDS.md
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("qs -c noctalia-shell --control-center"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("grim ~/Pictures/$(date +%s).png"))
hl.bind(",Delete", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/$(date +%s).png"))

-- Workspaces
for i = 1, 4 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
