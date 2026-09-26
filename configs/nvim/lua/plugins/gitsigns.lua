-- Blame/diff keymaps (<leader>gb, <leader>gB, <leader>go) live in
-- core/keymaps.lua, not here.
vim.pack.add({ { src = "https://github.com/lewis6991/gitsigns.nvim" } })

require("gitsigns").setup()
