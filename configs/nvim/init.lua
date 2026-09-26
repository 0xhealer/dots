if vim.loader then
  vim.loader.enable()
end

require("core.options")
require("core.autocmds")
require("core.commands")
require("core.ui")
require("utils")
require("plugins")
-- Loaded last, on purpose: keymaps below reference plugins (Snacks,
-- bufferline, gitsigns, multicursor-nvim, conform, oil, ...), so every
-- plugin needs to already be installed and set up by the time this runs.
require("core.keymaps")
