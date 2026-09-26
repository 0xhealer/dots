-- Editor-wide UI behavior that isn't any single plugin's setup: terminal
-- transparency (works across every colorscheme in lua/plugins/, since it's
-- a generic highlight-group sweep rather than any one theme's own
-- transparency option) and global diagnostic display.
--
-- StatusLine/StatusLineNC are deliberately NOT in the sweep below (unlike
-- everything else here). lualine's "auto" theme (lualine.lua) derives its
-- own section backgrounds from those two groups' bg -- specifically
-- StatusLine's bg for the centered mode+filename zone, and Normal/
-- StatusLineNC's bg as the fallback for the rest -- confirmed straight
-- from lualine's own lualine/themes/auto.lua source. With this sweep
-- forcing StatusLine to bg=none, lualine had nothing to derive a
-- background from and rendered fully transparent/flat instead of the
-- solid colored bar every one of these colorschemes actually ships by
-- default. Normal itself stays in the sweep -- this only opts the
-- statusline back into a solid background, not the rest of the editor.
local icons = require("utils.icons")

local function apply_transparency()
	local groups = {
		"Normal",
		"NormalNC",
		"NormalFloat",
		"FloatBorder",
		"FloatTitle",
		"SignColumn",
		"LineNr",
		"CursorLineNr",
		"EndOfBuffer",
		"TabLine",
		"TabLineFill",
		"TabLineSel",
		"WinSeparator",
		"VertSplit",
		"Pmenu",
		"PmenuSel",
		"PmenuSbar",
		"PmenuThumb",
		"WhichKeyFloat",
		"WhichKeyNormal",
		"InclineNormal",
		"InclineNormalNC",
	}
	for _, group in ipairs(groups) do
		vim.api.nvim_set_hl(0, group, { bg = "none" })
	end
end

apply_transparency()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = apply_transparency,
})

vim.diagnostic.config({
	underline = true,
	-- Live diagnostics while still typing, not just after dropping to
	-- Normal mode. Genuine tradeoff, not a strict improvement -- code is
	-- transiently "wrong" mid-edit (unclosed paren, half-typed identifier),
	-- so this trades some extra visual noise for not having to leave
	-- Insert mode to see whether what you just typed is actually broken.
	update_in_insert = true,
	virtual_text = {
		spacing = 4,
		source = "if_many",
		prefix = "●",
		format = function(diagnostic)
			return string.format("%s (%s: %s)", diagnostic.message, diagnostic.source, diagnostic.code)
		end,
	},
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
			[vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
			[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
			[vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
		},
	},
})
