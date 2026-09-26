-- All keymaps (gd, K, <leader>ca, <leader>f, etc.) live in core/keymaps.lua,
-- not here.
vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
})

require("mason").setup()

-- Bridges mason.nvim <-> nvim-lspconfig: translates between lspconfig
-- server names (used below and in every after/lsp/*.lua file) and Mason's
-- own package names, so this list doesn't have to be hand-mapped anymore.
-- That hand-mapping is exactly what produced the earlier "Cannot find
-- package 'rustfmt'" bug (see the mason-tool-installer comment below) --
-- this is the actual fix for that whole class of bug, not just that one
-- instance of it.
--
-- automatic_enable defaults to true, meaning mason-lspconfig calls
-- vim.lsp.enable() itself for everything in ensure_installed once Mason
-- has it installed -- so the old standalone vim.lsp.enable({...}) call
-- below is gone; this list is now the single source of truth for which
-- servers are active. Requires nvim-lspconfig already on runtimepath,
-- which vim.pack.add above guarantees by the time this file reaches here.
require("mason-lspconfig").setup({
	ensure_installed = {
		"eslint",
		"oxlint",
		"lua_ls",
		"cssls",
		"html",
		"vtsls",
		"tailwindcss",
		"rust_analyzer",
		"clangd",
		"basedpyright",
		"ruff",
		"gopls",
		"marksman",
		"bashls",
		"jsonls",
		"yamlls",
		"dockerls",
		"jdtls",
		"phpactor",
		"omnisharp",
		"solargraph",
		"powershell_es",
	},
})

-- Pure formatters/linters with no LSP server of their own -- these were
-- never part of the name-mapping problem above, so they stay here,
-- installed by name exactly as Mason's registry has them.
require("mason-tool-installer").setup({
	ensure_installed = {
		"prettier",
		"prettierd",
		"selene",
		"shellcheck",
		"shfmt",
		"stylua",
		"oxfmt",
		"clang-format",
		-- "rustfmt" deliberately NOT here — Mason deprecated this package
		-- (confirmed: mason-org/mason.nvim#1429). rustfmt is meant to come from
		-- `rustup component add rustfmt` instead, which install.sh's rustcall()
		-- already gets for free — rustup's default install profile includes
		-- rustfmt and clippy alongside rustc/cargo. Leaving this in ensure_installed
		-- is exactly what produced "Cannot find package 'rustfmt'".
		"goimports",
		"gofumpt",
	},
	auto_update = false,
	run_on_start = true,
})

local capabilities = {
	workspace = {
		fileOperations = {
			didRename = true,
			willRename = true,
		},
	},
}
vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities(capabilities),
})

-- Not in Mason's registry, so mason-lspconfig can't manage or auto-enable
-- it -- enabled directly, same as it always was.
vim.lsp.enable({ "glsl_analyzer" })
