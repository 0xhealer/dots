-- powershell_es can't run on bare defaults the way most servers here do —
-- confirmed against real working configs (neovim/nvim-lspconfig#2747,
-- mason-org/mason.nvim#262): it needs bundle_path pointing at where Mason
-- actually installed it, and it runs through pwsh specifically (PowerShell
-- 7+, cross-platform), not the old Windows PowerShell.
local bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services"
local log_path = vim.fn.stdpath("cache")

local command = ([[
& '%s/PowerShellEditorServices/Start-EditorServices.ps1'
    -BundledModulesPath '%s'
    -LogPath '%s/powershell_es.log'
    -SessionDetailsPath '%s/powershell_es.session.json'
    -FeatureFlags @()
    -AdditionalModules @()
    -HostName nvim
    -HostProfileId 0
    -HostVersion 1.0.0
    -Stdio
    -LogLevel Normal
]]):gsub("\n", " "):format(bundle_path, bundle_path, log_path, log_path)

return {
	cmd = { "pwsh", "-NoLogo", "-Command", command },
	filetypes = { "ps1" },
}
