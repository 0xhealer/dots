-- <leader>gd (toggle overlay) lives in core/keymaps.lua, not here.
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.diff" } })

require("mini.diff").setup({
	view = {
		-- show whole reference part above whole buffer part, as in `git diff`
		overlay_style = "hunk",
	},
	mappings = {
		-- same keymaps as codediff.nvim
		goto_next = "]c",
		goto_prev = "[c",
	},
})
