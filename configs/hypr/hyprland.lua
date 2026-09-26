-- Hyprland config (Lua format, Hyprland 0.55+). Older Hyprland reads
-- hyprland.conf instead -- functions/07-hyprland.sh deploys the right one
-- for the installed version. Keep both in step with assets/keybindings.txt.
--
-- Colours are NOT set here: they come from the wallpaper-driven palette
-- (~/.config/theme/theme.conf, rendered by theme-apply).

------------------
---- MONITORS ----
------------------
-- scale = 1 explicit, NOT "auto" -- real precedent from the NixOS box:
-- "auto" picked a bad HiDPI factor there too and inflated/misrendered
-- everything across multiple apps simultaneously, fixed by forcing
-- scale=1. Same failure class as the scaling glitches seen here
-- (torn/misaligned rendering in a browser window) -- worth trying the
-- same fix that already worked once on this same VM-testing pattern.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

-------------------------------
---- TEMPORARY: VM RENDERING ----
-------------------------------
-- REMOVED (was here): WLR_RENDERER=pixman and related software-render
-- env vars. That was based on real precedent from the NixOS box, but
-- direct evidence from this VM says otherwise -- Noctalia's own log
-- showed a successful hardware-accelerated GLES 3.1 context via
-- VMware's SVGA3D driver, then Hyprland severed its Wayland connection
-- ("Broken pipe") right as it tried to composite the wallpaper texture.
-- That's consistent with Hyprland's pixman (software) compositor being
-- unable to handle a real GPU-backed buffer from a hardware-rendered
-- client -- i.e. the forced-software renderer was CAUSING this crash,
-- not preventing one. This VM's driver stack can apparently do real
-- hardware GL; letting Hyprland use its normal renderer instead.
--
-- This means the original kitty OpenGL failure needs to be re-tested
-- without this override -- it may have had a different cause, or may
-- come back. If it does, that's new evidence to work from, not a
-- reason to silently re-add software rendering and reintroduce this
-- Noctalia crash.

---------------------
---- MY PROGRAMS ----
---------------------
local bin = (os and os.getenv and os.getenv("HOME") or "") .. "/.local/bin"
local terminal = bin .. "/dots-term"          -- kitty > ghostty > foot
local fileManager = "thunar"
local browser = bin .. "/dots-browser"        -- helium > brave > firefox ...
local themeApply = (os and os.getenv and os.getenv("HOME") or "") .. "/.config/theme/theme-apply"

-- Palette from the wallpaper (see theme-apply). Falls back to a fixed
-- default if the generated file is missing so the config still loads.
local theme = (function()
    local home = (os and os.getenv and os.getenv("HOME")) or ""
    local ok, t = pcall(dofile, home .. "/.config/theme/generated/hyprland.lua")
    if ok and type(t) == "table" then return t end
    return { active_border = "rgba(89b4faee)", active_border2 = "rgba(cba6f7ee)", inactive_border = "rgba(585b70aa)" }
end)()

-------------------
---- AUTOSTART ----
-------------------
-- Everything is guarded so a missing optional program can't break the session.
hl.on("hyprland.start", function()
    hl.exec_cmd(themeApply .. " --restore")                                   -- wallpaper + palette
    hl.exec_cmd("sh -c 'command -v noctalia >/dev/null && exec noctalia'")     -- optional shell (Arch)
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("sh -c 'command -v vicinae >/dev/null && exec vicinae server'")
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
        col = {
            active_border = { colors = { theme.active_border, theme.active_border2 }, angle = 45 },
            inactive_border = theme.inactive_border,
        },
    },
    decoration = {
        rounding = 8,
        -- Transparency -- confirmed fields from Hyprland's own example
        -- config. 1.0 = opaque; lower = more see-through.
        -- active_opacity kept close to inactive_opacity on purpose --
        -- the original 0.95/0.85 split made focused windows jump to
        -- near-opaque on click, which read as "losing the glass look"
        -- the moment you actually used the terminal. Small gap instead
        -- of a big one keeps the glass effect while focused too.
        active_opacity = 0.88,
        inactive_opacity = 0.78,
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            vibrancy = 0.17,
        },
    },
})

-- Blur/transparency for Noctalia's own surfaces (bar, panels, dock,
-- notifications, OSD). NOW CONFIRMED for v5 specifically -- the same
-- real Hyprland+Noctalia-v5+CachyOS dotfiles repo that fixed the
-- autostart bug also gives the actual v5 layer-shell namespace
-- pattern, which is NOT what I'd carried over from v4
-- ("noctalia-background-.*$" was a v4 guess that never got confirmed
-- for v5 -- this replaces it with a real one).
hl.layer_rule({
    name = "noctalia",
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$" },
    no_anim = true,
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

-- Noctalia's Settings window is a regular window, not a layer-shell
-- surface -- without this it tiles like any other window instead of
-- floating as a proper settings dialog. Window class confirmed from
-- the same real reference as the layer_rule above.
hl.window_rule({
    name = "noctalia-settings-float",
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size = { 1080, 920 },
})

---------------------
---- KEYBINDINGS ----
---------------------
-- (app name) -- for a Hyprland cheatsheet, see the Mod+Shift+Slash bind
-- at the bottom, which opens assets/keybindings.txt. Hyprland has no
-- built-in hotkey-overlay like Niri does, so this is a plain text file
-- instead -- same pattern already used on the NixOS box.
local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))                          -- (terminal: kitty > ghostty > foot)
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))                     -- (terminal)
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("ghostty"))            -- (ghostty)
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.exec_cmd("foot"))                -- (foot)

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("rofi -show drun"))                 -- (Rofi launcher)
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("rofi -show drun"))             -- (Rofi launcher)
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("rofi -show run"))          -- (Rofi run)
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.exec_cmd("rofi -show window"))   -- (Rofi window switcher)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(themeApply .. " --pick"))           -- (pick wallpaper + re-theme)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(themeApply .. " --random")) -- (random wallpaper + re-theme)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("spotify"))                        -- (Spotify -- manual install, skipped in aur.txt)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))                      -- (Thunar)
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))                          -- (browser)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())                        -- (fullscreen toggle)
hl.bind(mainMod .. " + Q", hl.dsp.window.close())                             -- (close window)
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("sh -c 'command -v noctalia >/dev/null && noctalia msg session lock'"))    -- (Noctalia lock screen)
-- v5: confirmed IPC command, replaces the old v4 --control-center flag
-- (which was itself an UNVERIFIED placeholder that never got confirmed).
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("sh -c 'command -v noctalia >/dev/null && noctalia msg panel-toggle control-center'")) -- (Noctalia control center)
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))        -- (toggle floating)

hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("grim ~/Pictures/$(date +%s).png"))       -- (grim, full screenshot)
hl.bind("Delete", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/$(date +%s).png"))     -- (grim+slurp, region screenshot)

-- Cheatsheet: all keybinds + app names, deployed by functions/10-assets.sh
hl.bind(mainMod .. " + SHIFT + Slash", hl.dsp.exec_cmd(terminal .. " -e less " .. (os and os.getenv and os.getenv("HOME") or "") .. "/.config/keybindings.txt")) -- (keybindings.txt cheatsheet)

-- Workspaces
for i = 1, 4 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
