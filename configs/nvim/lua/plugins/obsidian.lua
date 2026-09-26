-- obsidian-nvim/obsidian.nvim — the actively-maintained community fork
-- (epwalsh/obsidian.nvim is unmaintained). Completion works via an
-- in-process LSP the plugin registers itself, so it needs no wiring into
-- blink.cmp (blink.lua) — it "just works" the same way any other LSP
-- source does once you're in a markdown buffer inside the vault.
-- picker.name is set to snacks.picker since this config already uses
-- Snacks for every other picker (snacks.lua, core/keymaps.lua).
vim.pack.add({
	{ src = "https://github.com/obsidian-nvim/obsidian.nvim", version = vim.version.range("*") },
})

require("obsidian").setup({
	legacy_commands = false, -- will be removed upstream in 4.0.0 anyway
	workspaces = {
		{
			name = "0xhealer",
			path = "G:/My Drive/0xhealer",
		},
	},
	picker = {
		name = "snacks.picker",
	},
})
