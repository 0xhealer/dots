-- <leader>f (format buffer) lives in core/keymaps.lua, not here.
vim.pack.add({ { src = "https://github.com/stevearc/conform.nvim" } })

local oxfmtFormatter = { "oxfmt", "prettierd", "prettier", stop_after_first = true }
require("conform").setup({
	default_format_opts = {
		timeout_ms = 3000,
		async = false,
		quiet = false,
		lsp_format = "fallback",
	},
	formatters_by_ft = {
		javascript = oxfmtFormatter,
		typescript = oxfmtFormatter,
		javascriptreact = oxfmtFormatter,
		typescriptreact = oxfmtFormatter,
		json = oxfmtFormatter,
		css = oxfmtFormatter,
		html = oxfmtFormatter,
		markdown = oxfmtFormatter,
		yaml = oxfmtFormatter,
		less = oxfmtFormatter,
		scss = oxfmtFormatter,
		["markdown.mdx"] = oxfmtFormatter,
		lua = { "stylua" },
		sh = { "shfmt" },
		fish = { "fish_indent" },
		c = { "clang-format" },
		cpp = { "clang-format" },
		rust = { "rustfmt" },
		go = { "goimports", "gofumpt" },
		python = { "ruff_format" },
	},
	formatters = {
		oxfmt = {
			-- Treat oxfmt as available only when the project has an oxfmt config
			-- (.oxfmtrc.json / .oxfmtrc.jsonc). Without it, oxfmt is skipped and the
			-- formatter list falls back to prettier.
			require_cwd = true,
		},
	},
	format_on_save = function(bufnr)
		if vim.b[bufnr].disable_autoformat then
			return
		end
		return {
			timeout_ms = 500,
			lsp_fallback = true,
		}
	end,
})
