vim.api.nvim_create_user_command("ToggleFormatter", function()
	require("utils.editor").toggle_formatter()
end, { desc = "Toggle formatter for current buffer" })

-- Ported/adapted from SalarAlo/neovim_configuration's lua/salar/tools/skeleton.lua
-- (C version — no namespaces/classes, see lua/tools/skeleton_c.lua's own header
-- comment for exactly what changed from the original).
vim.api.nvim_create_user_command("SkelC", function()
	require("tools.skeleton_c").insert()
end, { desc = "Insert a C header/source skeleton for the current file" })
