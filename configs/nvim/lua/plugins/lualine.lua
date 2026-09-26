-- Statusline, styled after yeripratama.com/blog/customizing-nvim-lualine
-- (no separators, custom left/right component conditions), with mode +
-- filename kept in a genuinely centered third zone on top of that (the
-- blog itself only does left/right -- see the "%=" comment below for how
-- the centering works).
--
-- One deliberate deviation from the blog: it hardcodes
-- `require("tokyonight.colors").moon()` and threads exact hex values into
-- every component. This config has 6 colorschemes and a live picker
-- (<leader>uc, core/keymaps.lua) -- hardcoding one theme's palette here
-- would leave the statusline looking like tokyonight even after switching
-- to catppuccin/gruvbox/etc. `options.theme` is left on lualine's default
-- ("auto") instead, which tracks whichever colorscheme is actually active.
--
-- Diagnostic/git icons reuse utils/icons.lua (the same set core/ui.lua
-- uses for diagnostic signs) rather than a second, disconnected icon set.
local icons = require("utils.icons")

vim.pack.add({ { src = "https://github.com/nvim-lualine/lualine.nvim" } })

local conditions = {
	buffer_not_empty = function()
		return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
	end,
	screen_width = function(min_w)
		return function()
			return vim.o.columns > min_w
		end
	end,
	check_git_workspace = function()
		local filepath = vim.fn.expand("%:p:h")
		local gitdir = vim.fn.finddir(".git", filepath .. ";")
		return gitdir and #gitdir > 0 and #gitdir < #filepath
	end,
}

require("lualine").setup({
	options = {
		component_separators = "",
		section_separators = "",
	},
	sections = {
		lualine_a = {},
		lualine_b = {
			{
				"branch",
				icon = "",
				cond = conditions.check_git_workspace,
			},
			{
				"diff",
				symbols = {
					added = icons.git.added,
					modified = icons.git.modified,
					removed = icons.git.removed,
				},
				cond = conditions.screen_width(80),
			},
			{
				"diagnostics",
				sources = { "nvim_workspace_diagnostic" },
				symbols = {
					error = icons.diagnostics.Error,
					warn = icons.diagnostics.Warn,
					info = icons.diagnostics.Info,
					hint = icons.diagnostics.Hint,
				},
			},
		},
		lualine_c = {
			{ function() return "%=" end }, -- boundary 1: opens the centered zone
			"mode",
			{ "filename", path = 1, cond = conditions.buffer_not_empty },
		},
		lualine_x = {
			{
				"filetype",
				cond = function()
					return vim.fn.reg_recording() == ""
				end,
			},
			{
				function()
					return "Recording @" .. vim.fn.reg_recording()
				end,
				cond = function()
					return vim.fn.reg_recording() ~= ""
				end,
				padding = 1,
			},
		},
		lualine_y = {
			{ "location", cond = conditions.buffer_not_empty },
			{ "encoding", cond = conditions.screen_width(80) },
		},
		lualine_z = {},
		-- (boundary 2, closing the centered zone, is lualine's own automatic
		-- "%=" between section c and section x -- nothing to add for that one)
	},
	extensions = { "quickfix", "oil" },
})
