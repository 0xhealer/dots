-- Buffer tabs at the top of the window. This is a separate concept from
-- this config's existing <tab>/<s-tab>/te bindings (core/keymaps.lua),
-- which navigate real Vim tab-pages — bufferline shows the open *buffers*
-- within whichever tab-page you're currently on. Cycling keymaps therefore
-- deliberately live on ]b/[b, not <tab>/<s-tab>, to avoid colliding with
-- the tab-page bindings that were already there. All keymaps live in
-- core/keymaps.lua, not here.
--
-- Icons come from mini.icons' nvim-web-devicons mock (mini-icons.lua),
-- so no separate icon plugin dependency needed.
vim.pack.add({ { src = "https://github.com/akinsho/bufferline.nvim" } })

require("bufferline").setup({
	options = {
		mode = "buffers",
		diagnostics = "nvim_lsp",
		always_show_bufferline = true,
		show_buffer_close_icons = true,
		show_close_icon = false,
		separator_style = "thin",
	},
})
