-- All colorschemes live together in this one file, unlike every other
-- plugin in lua/plugins/ (each of which gets its own file) -- kept together
-- deliberately since they're one coherent "theming" concern sharing a
-- single picker (<leader>uc, core/keymaps.lua), not independent features.
--
-- Curated down to dark variants only. `vim.o.background = "dark"` is set
-- once, globally, for the two schemes below (gruvbox, horizon) that take
-- their light/dark cue from that option rather than their own setup()
-- field -- the rest are pinned to an explicitly dark variant/flavour in
-- their own setup() call regardless, so this is belt-and-suspenders for
-- those two, not load-bearing for the others.
--
-- Transparency: apply_transparency()'s ColorScheme autocmd (core/ui.lua)
-- is the real safety net that makes every one of these actually match a
-- transparent terminal -- the per-theme transparency option is set too
-- where the plugin exposes one, but core/ui.lua's generic sweep is what's
-- doing the heavy lifting for the ones that don't (horizon has no
-- transparency option of its own at all).
vim.o.background = "dark"

vim.pack.add({
	{ src = "https://github.com/rose-pine/neovim", name = "rose-pine" },
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	{ src = "https://github.com/folke/tokyonight.nvim" },
	{ src = "https://github.com/ellisonleao/gruvbox.nvim" },
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/craftzdog/solarized-osaka.nvim" },
	{ src = "https://github.com/akinsho/horizon.nvim" },
	{ src = "https://github.com/Mofiqul/dracula.nvim" },
})

require("rose-pine").setup({
	-- "main", not "auto" -- auto follows vim.o.background and would fall
	-- back to the light "dawn" variant if that option ever gets flipped;
	-- dark-only means pinning this explicitly, not just defaulting to it.
	variant = "main",
	dark_variant = "main",
	dim_inactive_windows = false,
	extend_background_behind_borders = true,
	enable = {
		terminal = true,
		legacy_highlights = true,
		migrations = true,
	},
	styles = {
		bold = true,
		italic = true,
		transparency = true,
	},
})

require("catppuccin").setup({
	flavour = "mocha", -- the darkest of catppuccin's flavours
	transparent_background = true,
})

require("tokyonight").setup({
	style = "night", -- storm, moon, or night -- NOT "day" (tokyonight's light variant)
	transparent = true,
})

require("gruvbox").setup({
	transparent_mode = true,
})

require("kanagawa").setup({
	transparent = true,
	-- theme variant is picked via colorscheme name, not a setup option --
	-- "kanagawa" (wave, the default) or "kanagawa-dragon" are both dark;
	-- "kanagawa-lotus" is kanagawa's light variant, deliberately not used.
})

require("solarized-osaka").setup({
	style = "vivid",
	transparent = true,
	styles = {
		sidebars = "transparent",
		floats = "transparent",
	},
	sidebars = {
		"qf",
		"vista_kind",
		"terminal",
		"spectre_panel",
		"startuptime",
		"Outline",
	},
})

require("horizon").setup({
	plugins = {
		bufferline = true,
		gitsigns = true,
		whichkey = true,
	},
})

require("dracula").setup({
	transparent_bg = true,
})

-- Default on startup -- change this line (or use the <leader>uc picker,
-- core/keymaps.lua) if you want a different one to load by default going
-- forward.
vim.cmd([[colorscheme rose-pine]])
