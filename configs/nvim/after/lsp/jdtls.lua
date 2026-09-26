-- jdtls needs a unique, persistent workspace directory PER PROJECT — this
-- isn't optional customization the way most after/lsp files here are, it's
-- a real jdtls requirement. Without it, every Java project you open shares
-- one workspace cache and jdtls's project-state tracking breaks across them.
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

return {
	cmd = { "jdtls", "-data", workspace_dir },
}
