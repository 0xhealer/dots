-- Every plugin lives in its own file: vim.pack.add({...}) for that plugin
-- plus its own setup()/config, colocated. Keymaps are NOT here — every
-- vim.keymap.set call for every plugin below lives in core/keymaps.lua,
-- which is required last (after this file) precisely so those keymaps can
-- safely `require` any plugin below by then.

-- Colorschemes (single file — see lua/plugins/colorschemes.lua for why)
require("plugins.colorschemes")

-- Icons / UI shell
require("plugins.mini-icons")
require("plugins.snacks")
require("plugins.bufferline")
require("plugins.lualine")
require("plugins.tiny-cmdline")
require("plugins.incline")

-- Editing
require("plugins.treesitter")
require("plugins.blink")
require("plugins.mini-pairs")
require("plugins.mini-diff")
require("plugins.multicursor")
require("plugins.todo-comments")
require("plugins.conform")
require("plugins.nvim-highlight-colors")

-- Git
require("plugins.gitsigns")
require("plugins.gitlinker")
require("plugins.codediff")

-- LSP (after blink, which its capabilities() call depends on)
require("plugins.lsp")

-- Util
require("plugins.oil")
require("plugins.obsidian")

-- Which-key (last: only registers group labels, doesn't care about order)
require("plugins.whichkey")
