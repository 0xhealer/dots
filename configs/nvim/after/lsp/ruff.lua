---@type vim.lsp.Config
return {
	-- basedpyright already provides hover/go-to-definition; keep ruff scoped
	-- to linting + import sorting so hovers/diagnostics aren't duplicated.
	on_attach = function(client)
		client.server_capabilities.hoverProvider = false
	end,
}
