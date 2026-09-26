-- Multiple cursors, VSCode-style: add cursors, then type/edit once and it
-- applies to all of them simultaneously (unlike smoka7/multicursors.nvim's
-- enter-a-mode-then-batch-apply workflow, which is a different, more Vim-
-- native design). setup() only here — every keymap that drives it lives in
-- core/keymaps.lua now (it `require`s this same module directly).
vim.pack.add({ { src = "https://github.com/jake-stewart/multicursor.nvim", version = "1.0" } })

require("multicursor-nvim").setup()
