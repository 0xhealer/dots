-- which-key: on-demand keybinding reference. setup() and the group labels
-- below aren't real keymaps (no vim.keymap.set calls), so they stay here;
-- the actual <leader>? binding that opens it lives in core/keymaps.lua.
vim.pack.add({ { src = "https://github.com/folke/which-key.nvim" } })

require("which-key").setup({
	preset = "modern",
})

require("which-key").add({
	{ "<leader>b", group = "Buffers" },
	{ "<leader>c", group = "Code" },
	{ "<leader>d", group = "Diff" },
	{ "<leader>g", group = "Git" },
	{ "<leader>t", group = "Terminal" },
	{ "<leader>u", group = "UI" },
	{ "<leader>y", group = "Yank path" },
	{ "s", group = "Split / Window" },
	{ ";", group = "Find (Snacks)" },
})
